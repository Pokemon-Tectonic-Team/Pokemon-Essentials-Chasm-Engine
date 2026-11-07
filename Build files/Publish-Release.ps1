<#
.SYNOPSIS
    Publishes a built release: uploads zips to Google Drive, updates the
    public version-list blob, deploys the Cable Club server to live, and
    kicks off the tools-website rebuild.

.DESCRIPTION
    Separate from Zip-Release.ps1 on purpose: Zip-Release.ps1 stays
    dependency-free so any dev can build a release zip with nothing but
    PowerShell, while this script carries the extra setup cost (rclone,
    Azure, SSH access, gh CLI) and is only expected to be run by whoever is
    actually publishing a release.

    Four steps, all run by default. Pass one or more -Only<Step> switches to
    isolate just those steps (e.g. to update the version list for zips
    already uploaded in a prior run), or one or more -Skip<Step> switches to
    run everything except those (e.g. to publish while a step's credentials
    aren't set up yet). -Only<Step> takes precedence if both are given.
    The selected steps' prerequisites (tools on PATH, the zips, credentials,
    the release tag, etc.) are all checked before any step runs, dry run
    included.

    -DryRun makes every step perform a real, read-only verification instead
    of just logging intent -- a missing tool, bad credentials, or a wrong
    ID/URL surfaces as a real error here, not silently: Drive upload passes
    rclone's own --dry-run through; the version-list step HEADs the SAS
    URL; Cable Club runs `-Status` against live instead of deploying;
    tools-website reads
    tectonic-data's current PUBLIC_VERSION_COMMIT instead of writing it, and
    runs `gh workflow view` instead of `gh workflow run`.

.PARAMETER Version
    Release version in X.Y.Z form, e.g. 3.2.4. Used to locate the zips built
    by Zip-Release.ps1 in Releases/ -- must match the -Version it was run
    with.

.PARAMETER GameTitle
    Display name used in zip filenames. Must match what Zip-Release.ps1 was
    run with.

.PARAMETER DriveFolderId
    Google Drive folder ID to upload into (the id in the folder's share
    link). Defaults to the shared Pokemon Tectonic releases folder;
    downstream games should override.

.PARAMETER RcloneRemote
    Name of the rclone remote to upload through. Each publisher runs
    `rclone config` once to create a remote with this name, authorized
    against their own Google account.

.PARAMETER AzureBlobSasUrl
    A SAS URL granting write access to the version_order.txt blob read by
    IntroScene.rb (VERSION_SERVER_FILE_URL in GameSettings.rb). Falls back to
    $env:VERSION_LIST_SAS_URL, then a VERSION_LIST_SAS_URL line in
    Build files/.env (gitignored). Required for the version-list step.

.PARAMETER OnlyUpload
    Run only the Google Drive upload step.

.PARAMETER OnlyVersionList
    Run only the public version-list blob update.

.PARAMETER OnlyCableClubLive
    Run only the Cable Club live deploy (via deploy_cableclub.ps1 -Live).

.PARAMETER OnlyToolsWebsite
    Run only the tools-website update: pins PUBLIC_VERSION_COMMIT in
    tectonic-data to the vX.Y.Z tag's commit, then triggers tectonic-data's
    build workflow and waits for it to finish (tectonic-tools' deploy reads
    its output) before triggering tectonic-tools' deploy workflow.

.PARAMETER SkipUpload
    Run every step except the Google Drive upload.

.PARAMETER SkipVersionList
    Run every step except the public version-list blob update.

.PARAMETER SkipCableClubLive
    Run every step except the Cable Club live deploy.

.PARAMETER SkipToolsWebsite
    Run every step except the tools-website update (version pin + workflow
    triggers).

.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -AzureBlobSasUrl "https://..."
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -AzureBlobSasUrl "https://..." -DryRun
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -OnlyUpload
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -AzureBlobSasUrl "https://..." -SkipCableClubLive
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$GameTitle = "Pokemon Tectonic",

    [string]$DriveFolderId = "1ZkpLqyPlt8fqeff9kqFWYBcIpzwESE8_",
    [string]$RcloneRemote = "gdrive",

    [string]$AzureBlobSasUrl,

    [switch]$OnlyUpload,
    [switch]$OnlyVersionList,
    [switch]$OnlyCableClubLive,
    [switch]$OnlyToolsWebsite,

    [switch]$SkipUpload,
    [switch]$SkipVersionList,
    [switch]$SkipCableClubLive,
    [switch]$SkipToolsWebsite,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$BuildFilesDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $BuildFilesDir
$OutputDir = Join-Path $BuildFilesDir "Releases"

# Loads Build files/.env (gitignored) into the process environment
# so credentials never need to be pasted on the command line or hardcoded.
# Doesn't override a variable that's already set in the environment.
$dotEnvPath = Join-Path $BuildFilesDir ".env"
if (Test-Path $dotEnvPath) {
    foreach ($line in Get-Content $dotEnvPath) {
        if ($line -notmatch '^\s*([^#=\s][^=]*)\s*=\s*(.*)$') { continue }
        $key = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"')
        if (-not (Test-Path "Env:$key")) { Set-Item -Path "Env:$key" -Value $value }
    }
}

if (-not $AzureBlobSasUrl) { $AzureBlobSasUrl = $env:VERSION_LIST_SAS_URL }

$VersionListUrl = "https://tectonicstorage.blob.core.windows.net/tectonicstorage/version_order.txt"

$ToolsWebsiteTargets = @(
    @{ Repo = 'Pokemon-Tectonic-Team/tectonic-data'; Workflow = 'build-public.yml' },
    @{ Repo = 'Pokemon-Tectonic-Team/tectonic-tools'; Workflow = 'deploy.yml' }
)

$versionParts = $Version.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]
$tagName = "v$Version"

$DataRepo = 'Pokemon-Tectonic-Team/tectonic-data'
$DataRepoVersionFile = 'src/loadTectonicRepoData.ts'

$installZipPath = Join-Path $OutputDir "$GameTitle $Version.zip"
$patchZipPath = Join-Path $OutputDir "$GameTitle $major.$minor -- Patch $patch.zip"
$zipsToPublish = @(@($installZipPath, $patchZipPath) | Where-Object { Test-Path $_ })

$deployScript = Join-Path $RepoRoot "deploy_cableclub.ps1"

# Filled in by Assert-Prerequisites; workflows are dispatched on each repo's default branch.
$defaultBranches = @{}

$OnlySteps = @{
    Upload        = $OnlyUpload
    VersionList   = $OnlyVersionList
    CableClubLive = $OnlyCableClubLive
    ToolsWebsite  = $OnlyToolsWebsite
}
$SkipSteps = @{
    Upload        = $SkipUpload
    VersionList   = $SkipVersionList
    CableClubLive = $SkipCableClubLive
    ToolsWebsite  = $SkipToolsWebsite
}
$AnyOnlySet = @($OnlySteps.Values) -contains $true

function Test-StepEnabled([string]$Name) {
    if ($AnyOnlySet) { return $OnlySteps[$Name] }
    return -not $SkipSteps[$Name]
}

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-DryRun($msg) { Write-Host "[DryRun] $msg" -ForegroundColor Yellow }

function Assert-Prerequisites {
    # Windows PowerShell 5.1 turns redirected native stderr into a terminating
    # error under 'Stop'; a failing check must be collected, not thrown.
    $ErrorActionPreference = 'Continue'
    $problems = [System.Collections.Generic.List[string]]::new()
    function Test-Tool([string]$Name, [string]$Hint) {
        if (Get-Command $Name -ErrorAction SilentlyContinue) { return $true }
        $problems.Add("$Name not found on PATH. $Hint")
        return $false
    }

    if (Test-StepEnabled 'Upload') {
        if ($zipsToPublish.Count -eq 0) {
            $problems.Add("No release zips found in $OutputDir matching version $Version. Run Zip-Release.ps1 first.")
        }
        $rcloneSetup = "run 'rclone config' to create a remote named '$RcloneRemote' authorized against your Google account."
        if (Test-Tool 'rclone' "Install it and $rcloneSetup") {
            if (@(& rclone listremotes) -notcontains "${RcloneRemote}:") {
                $problems.Add("rclone has no remote named '$RcloneRemote'. To fix, $rcloneSetup")
            }
        }
    }

    if ((Test-StepEnabled 'VersionList') -and -not $AzureBlobSasUrl) {
        $problems.Add("No Azure blob SAS URL given. Pass -AzureBlobSasUrl, set `$env:VERSION_LIST_SAS_URL, or add VERSION_LIST_SAS_URL to Build files/.env.")
    }

    if (Test-StepEnabled 'CableClubLive') {
        if (-not (Test-Path $deployScript)) { $problems.Add("deploy_cableclub.ps1 not found at $deployScript") }
        Test-Tool 'ssh' "Install the Windows OpenSSH client." | Out-Null
        Test-Tool 'scp' "Install the Windows OpenSSH client." | Out-Null
    }

    if (Test-StepEnabled 'ToolsWebsite') {
        if (Test-Tool 'gh' "Install it and run 'gh auth login'.") {
            & gh auth status *> $null
            if ($LASTEXITCODE -ne 0) {
                $problems.Add("gh is not logged in. Run 'gh auth login'.")
            }
            else {
                # Pinning PUBLIC_VERSION_COMMIT and triggering workflows both need write access.
                $repos = @($DataRepo) + @($ToolsWebsiteTargets | ForEach-Object { $_.Repo }) | Select-Object -Unique
                foreach ($repo in $repos) {
                    $repoJson = & gh api "repos/$repo" 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        $problems.Add("Could not read $repo with gh. Check the repo name and that your GitHub account can see it.")
                        continue
                    }
                    $repoInfo = ($repoJson -join "`n") | ConvertFrom-Json
                    $script:defaultBranches[$repo] = $repoInfo.default_branch
                    if (-not $repoInfo.permissions.push) {
                        $problems.Add("Your GitHub account has no write access to $repo, which the tools-website step needs.")
                    }
                }
            }
        }
        if (Test-Tool 'git' "Install Git for Windows.") {
            $script:tagCommit = git -C $RepoRoot rev-list -n 1 "refs/tags/$tagName" 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $script:tagCommit) {
                $problems.Add("Tag '$tagName' not found in $RepoRoot. Zip-Release.ps1's Tag step creates it.")
            }
        }
    }

    if ($problems.Count -gt 0) {
        foreach ($problem in $problems) { Write-Host "  - $problem" -ForegroundColor Red }
        throw "Can't start publishing: $($problems.Count) prerequisite(s) missing, listed above."
    }
}

function Publish-ToDrive {
    if (-not (Test-StepEnabled 'Upload')) { Write-Step "Skipping Drive upload"; return }

    foreach ($zipPath in $zipsToPublish) {
        $zipName = Split-Path -Leaf $zipPath
        Write-Step "$(if ($DryRun) { '[DryRun] ' })Uploading $zipName to Drive folder $DriveFolderId..."
        $rcloneArgs = @('copy', $zipPath, "${RcloneRemote}:", '--drive-root-folder-id', $DriveFolderId, '--progress')
        if ($DryRun) { $rcloneArgs += '--dry-run' }
        & rclone @rcloneArgs
        if ($LASTEXITCODE -ne 0) { throw "rclone upload failed for $zipName (exit $LASTEXITCODE)" }
    }
}

function Publish-VersionList {
    if (-not (Test-StepEnabled 'VersionList')) { Write-Step "Skipping version-list update"; return }

    $currentBody = (Invoke-WebRequest -Uri $VersionListUrl -UseBasicParsing).Content
    $lines = @($currentBody -split "`r`n" | Where-Object { $_ -ne '' })

    if ($lines -contains $Version -and $lines[-1] -eq $Version) {
        Write-Step "$Version is already the latest entry in version_order.txt, nothing to do."
        return
    }

    if ($DryRun) {
        Write-DryRun "Verifying the SAS URL grants access (HEAD request)..."
        Invoke-WebRequest -Uri $AzureBlobSasUrl -Method Head -UseBasicParsing | Out-Null
        Write-DryRun "Would append '$Version' to version_order.txt (currently ends with '$($lines[-1])')"
        return
    }

    $newBody = (($lines + $Version) -join "`r`n") + "`r`n"
    Write-Step "Appending $Version to the public version-list blob..."
    Invoke-RestMethod -Uri $AzureBlobSasUrl -Method Put -Headers @{ 'x-ms-blob-type' = 'BlockBlob' } -ContentType 'text/plain' -Body $newBody | Out-Null
}

function Publish-CableClubLive {
    if (-not (Test-StepEnabled 'CableClubLive')) { Write-Step "Skipping Cable Club live deploy"; return }

    Push-Location $RepoRoot
    try {
        if ($DryRun) {
            Write-DryRun "Checking live Cable Club server status (deploy_cableclub.ps1 -Live -Status, read-only)..."
            & $deployScript -Live -Status
            if ($LASTEXITCODE -ne 0) { throw "Cable Club live status check failed (exit $LASTEXITCODE)" }
        }
        else {
            Write-Step "Deploying Cable Club server files to LIVE and restarting..."
            & $deployScript -Live
            if ($LASTEXITCODE -ne 0) { throw "Cable Club live deploy failed (exit $LASTEXITCODE)" }
        }
    }
    finally {
        Pop-Location
    }
}

function Update-DataVersionPin {
    $commitSha = $tagCommit.Trim()

    $fileJson = & gh api "repos/$DataRepo/contents/$DataRepoVersionFile" | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw "Failed to read $DataRepoVersionFile from $DataRepo (exit $LASTEXITCODE)" }
    $currentContent = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($fileJson.content))

    $pattern = 'const PUBLIC_VERSION_COMMIT = "[0-9a-f]{40}";'
    $match = [regex]::Match($currentContent, $pattern)
    if (-not $match.Success) {
        throw "Could not find a PUBLIC_VERSION_COMMIT line in $DataRepo/$DataRepoVersionFile -- file format may have changed."
    }
    $currentSha = $match.Value -replace '.*"([0-9a-f]{40})".*', '$1'

    if ($currentSha -eq $commitSha) {
        Write-Step "PUBLIC_VERSION_COMMIT in $DataRepo already points at $commitSha ($tagName), nothing to update."
        return
    }

    if ($DryRun) {
        Write-DryRun "Would update PUBLIC_VERSION_COMMIT in $DataRepo/$DataRepoVersionFile from $currentSha to $commitSha ($tagName)"
        return
    }

    $newContent = $currentContent -replace $pattern, "const PUBLIC_VERSION_COMMIT = `"$commitSha`";"
    $newContentB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($newContent))

    # Passed via a temp file, not inline -- the base64 blob is long enough to
    # blow past Windows' command-line length limit ("filename or extension is
    # too long" from gh.exe).
    $contentFile = [System.IO.Path]::GetTempFileName()
    try {
        # Set-Content's encoding varies by host and can add a BOM, corrupting
        # the base64 payload -- write raw ASCII bytes instead (base64 is
        # always pure ASCII).
        [System.IO.File]::WriteAllText($contentFile, $newContentB64, [System.Text.Encoding]::ASCII)
        Write-Step "Updating PUBLIC_VERSION_COMMIT in $DataRepo to $commitSha ($tagName)..."
        & gh api -X PUT "repos/$DataRepo/contents/$DataRepoVersionFile" `
            -f "message=Update PUBLIC_VERSION_COMMIT to $tagName" `
            -F "content=@$contentFile" `
            -f "sha=$($fileJson.sha)" `
            -f "branch=main" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to update $DataRepoVersionFile in $DataRepo (exit $LASTEXITCODE)" }
    }
    finally {
        Remove-Item -Path $contentFile -Force -ErrorAction SilentlyContinue
    }
}

# Returns the new run's ID, or $null if GitHub didn't send run details back.
function Start-WorkflowRun([string]$Workflow, [string]$Repo) {
    $response = & gh api -X POST "repos/$Repo/actions/workflows/$Workflow/dispatches" `
        -f "ref=$($defaultBranches[$Repo])" -F return_run_details=true
    if ($LASTEXITCODE -ne 0) { throw "Failed to trigger '$Workflow' on $Repo (exit $LASTEXITCODE)" }
    if (-not $response) { return $null }
    return (($response -join "`n") | ConvertFrom-Json).workflow_run_id
}

function Wait-WorkflowRun([string]$Workflow, [string]$Repo, [long]$RunId) {
    Write-Step "Watching run $RunId ('$Workflow' on $Repo) until it completes..."
    & gh run watch $RunId --repo $Repo --exit-status
    if ($LASTEXITCODE -ne 0) { throw "'$Workflow' on $Repo failed (run $RunId, exit $LASTEXITCODE) -- see https://github.com/$Repo/actions/runs/$RunId" }
}

function Publish-ToolsWebsite {
    if (-not (Test-StepEnabled 'ToolsWebsite')) { Write-Step "Skipping tools-website triggers"; return }

    Update-DataVersionPin

    for ($i = 0; $i -lt $ToolsWebsiteTargets.Count; $i++) {
        $target = $ToolsWebsiteTargets[$i]
        $isLast = $i -eq ($ToolsWebsiteTargets.Count - 1)

        if ($DryRun) {
            Write-DryRun "Verifying workflow '$($target.Workflow)' exists on $($target.Repo) (gh workflow view)..."
            & gh workflow view $target.Workflow --repo $target.Repo | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Could not find workflow '$($target.Workflow)' on $($target.Repo) -- check gh auth and the workflow name." }
            Write-DryRun "Would trigger '$($target.Workflow)' on $($target.Repo)"
        }
        else {
            Write-Step "Triggering '$($target.Workflow)' on $($target.Repo)..."
            $runId = Start-WorkflowRun -Workflow $target.Workflow -Repo $target.Repo
            if ($runId) { Write-Host "    https://github.com/$($target.Repo)/actions/runs/$runId" }

            # tectonic-tools' deploy reads tectonic-data's build output, so it
            # can't start until tectonic-data's run actually finishes -- wait
            # on every step but the last, where nothing downstream depends on it.
            if (-not $isLast) {
                if (-not $runId) {
                    $remaining = @($ToolsWebsiteTargets[($i + 1)..($ToolsWebsiteTargets.Count - 1)] |
                        ForEach-Object { "gh workflow run $($_.Workflow) --repo $($_.Repo)" })
                    throw "Triggered '$($target.Workflow)' on $($target.Repo), but GitHub didn't return its run ID, so its completion can't be awaited. Once it finishes (https://github.com/$($target.Repo)/actions/workflows/$($target.Workflow)), run: $($remaining -join '; ')"
                }
                Wait-WorkflowRun -Workflow $target.Workflow -Repo $target.Repo -RunId $runId
            }
        }
    }
}

# ---- main ----

Assert-Prerequisites

Publish-ToDrive
Publish-VersionList
Publish-CableClubLive
Publish-ToolsWebsite

Write-Step "Done."
