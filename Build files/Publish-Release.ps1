<#
.SYNOPSIS
    Publishes a built release: uploads zips to Google Drive, mints Short.io
    shortlinks for them, updates the public version-list blob, deploys the
    Cable Club server to live, and kicks off the tools-website rebuild.

.DESCRIPTION
    Separate from Zip-Release.ps1 on purpose: Zip-Release.ps1 stays
    dependency-free so any dev can build a release zip with nothing but
    PowerShell, while this script carries the extra setup cost (rclone,
    Short.io, Azure, SSH access, gh CLI) and is only expected
    to be run by whoever is actually publishing a release.

    Five steps, all run by default. Pass one or more -Only<Step> switches to
    isolate just those steps (e.g. to mint shortlinks for zips already
    uploaded in a prior run), or one or more -Skip<Step> switches to run
    everything except those (e.g. to publish while a step's credentials
    aren't set up yet). -Only<Step> takes precedence if both are given.

    -DryRun makes every step perform a real, read-only verification instead
    of just logging intent -- a missing tool, bad credentials, or a wrong
    ID/URL surfaces as a real error here, not silently: Drive upload passes
    rclone's own --dry-run through; shortlinks call Short.io's domain-list
    endpoint; the version-list step HEADs the SAS URL; Cable Club runs
    `-Status` against live instead of deploying; tools-website reads
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

.PARAMETER ShortIoApiKey
    Short.io API key. Falls back to $env:SHORTIO_API_KEY, then a
    SHORTIO_API_KEY line in Build files/.env (gitignored).
    Required for the shortlinks step.

.PARAMETER ShortIoDomain
    Short.io domain the links are created under (e.g. go.example.com),
    configured in your Short.io account. Falls back to $env:SHORTIO_DOMAIN,
    then a SHORTIO_DOMAIN line in .env. Required for the shortlinks step.

.PARAMETER AzureBlobSasUrl
    A SAS URL granting write access to the version_order.txt blob read by
    IntroScene.rb (VERSION_SERVER_FILE_URL in GameSettings.rb). Falls back to
    $env:VERSION_LIST_SAS_URL, then a VERSION_LIST_SAS_URL line in .env.
    Required for the version-list step.

.PARAMETER OnlyUpload
    Run only the Google Drive upload step.

.PARAMETER OnlyShortlinks
    Run only the Short.io shortlink step. Requires the zips to already be
    uploaded to Drive -- it looks up each one's share URL via `rclone link`
    rather than re-uploading.

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

.PARAMETER SkipShortlinks
    Run every step except the Short.io shortlink step.

.PARAMETER SkipVersionList
    Run every step except the public version-list blob update.

.PARAMETER SkipCableClubLive
    Run every step except the Cable Club live deploy.

.PARAMETER SkipToolsWebsite
    Run every step except the tools-website update (version pin + workflow
    triggers).

.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -ShortIoDomain go.example.com -AzureBlobSasUrl "https://..."
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -ShortIoDomain go.example.com -AzureBlobSasUrl "https://..." -DryRun
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -OnlyUpload
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -AzureBlobSasUrl "https://..." -SkipShortlinks
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$GameTitle = "Pokemon Tectonic",

    [string]$DriveFolderId = "1ZkpLqyPlt8fqeff9kqFWYBcIpzwESE8_",
    [string]$RcloneRemote = "gdrive",

    [string]$ShortIoApiKey,
    [string]$ShortIoDomain,

    [string]$AzureBlobSasUrl,

    [switch]$OnlyUpload,
    [switch]$OnlyShortlinks,
    [switch]$OnlyVersionList,
    [switch]$OnlyCableClubLive,
    [switch]$OnlyToolsWebsite,

    [switch]$SkipUpload,
    [switch]$SkipShortlinks,
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

if (-not $ShortIoApiKey) { $ShortIoApiKey = $env:SHORTIO_API_KEY }
if (-not $ShortIoDomain) { $ShortIoDomain = $env:SHORTIO_DOMAIN }
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

$OnlySteps = @{
    Upload        = $OnlyUpload
    Shortlinks    = $OnlyShortlinks
    VersionList   = $OnlyVersionList
    CableClubLive = $OnlyCableClubLive
    ToolsWebsite  = $OnlyToolsWebsite
}
$SkipSteps = @{
    Upload        = $SkipUpload
    Shortlinks    = $SkipShortlinks
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

function Get-ZipsToPublish {
    $zips = @($installZipPath, $patchZipPath) | Where-Object { Test-Path $_ }
    if (-not $zips) {
        throw "No release zips found in $OutputDir matching version $Version. Run Zip-Release.ps1 first."
    }
    return $zips
}

function Publish-ToDrive {
    if (-not (Test-StepEnabled 'Upload')) { Write-Step "Skipping Drive upload"; return }

    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        throw "rclone not found on PATH. Install it and run 'rclone config' to create a remote named '$RcloneRemote' authorized against your Google account."
    }

    foreach ($zipPath in (Get-ZipsToPublish)) {
        $zipName = Split-Path -Leaf $zipPath
        Write-Step "$(if ($DryRun) { '[DryRun] ' })Uploading $zipName to Drive folder $DriveFolderId..."
        $rcloneArgs = @('copy', $zipPath, "${RcloneRemote}:", '--drive-root-folder-id', $DriveFolderId, '--progress')
        if ($DryRun) { $rcloneArgs += '--dry-run' }
        & rclone @rcloneArgs
        if ($LASTEXITCODE -ne 0) { throw "rclone upload failed for $zipName (exit $LASTEXITCODE)" }
    }
}

function Get-DriveShareUrl([string]$ZipName) {
    if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
        throw "rclone not found on PATH. Install it and run 'rclone config' to create a remote named '$RcloneRemote' authorized against your Google account."
    }
    $url = & rclone link "${RcloneRemote}:$ZipName" --drive-root-folder-id $DriveFolderId
    if ($LASTEXITCODE -ne 0 -or -not $url) {
        throw "Could not get a Drive share link for $ZipName -- has it been uploaded yet? (run without -OnlyShortlinks first)"
    }
    return $url.Trim()
}

function New-ShortIoLink([string]$OriginalUrl) {
    $headers = @{
        Authorization = $ShortIoApiKey
        Accept        = 'application/json'
    }
    $body = @{
        domain      = $ShortIoDomain
        originalURL = $OriginalUrl
    } | ConvertTo-Json
    $response = Invoke-RestMethod -Uri 'https://api.short.io/links' -Method Post -Headers $headers -ContentType 'application/json' -Body $body
    return $response.shortURL
}

function Test-ShortIoAuth {
    $headers = @{ Authorization = $ShortIoApiKey; Accept = 'application/json' }
    Invoke-RestMethod -Uri 'https://api.short.io/api/domains' -Method Get -Headers $headers | Out-Null
}

function Publish-Shortlinks {
    if (-not (Test-StepEnabled 'Shortlinks')) { Write-Step "Skipping shortlinks"; return }

    if (-not $ShortIoApiKey) { throw "No Short.io API key given. Pass -ShortIoApiKey, set `$env:SHORTIO_API_KEY, or add SHORTIO_API_KEY to Build files/.env." }
    if (-not $ShortIoDomain) { throw "No Short.io domain given. Pass -ShortIoDomain, set `$env:SHORTIO_DOMAIN, or add SHORTIO_DOMAIN to Build files/.env." }

    if ($DryRun) {
        Write-DryRun "Verifying Short.io API key/domain via a real API call (GET /api/domains)..."
        Test-ShortIoAuth
    }

    foreach ($zipPath in (Get-ZipsToPublish)) {
        $zipName = Split-Path -Leaf $zipPath
        $driveUrl = Get-DriveShareUrl -ZipName $zipName
        if ($DryRun) {
            Write-DryRun "Would create Short.io link on $ShortIoDomain for $zipName -> $driveUrl"
        }
        else {
            Write-Step "Creating Short.io link for $zipName..."
            $shortUrl = New-ShortIoLink -OriginalUrl $driveUrl
            Write-Host "    $zipName -> $shortUrl"
        }
    }
}

function Publish-VersionList {
    if (-not (Test-StepEnabled 'VersionList')) { Write-Step "Skipping version-list update"; return }
    if (-not $AzureBlobSasUrl) { throw "No Azure blob SAS URL given. Pass -AzureBlobSasUrl, set `$env:VERSION_LIST_SAS_URL, or add VERSION_LIST_SAS_URL to Build files/.env." }

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

    $deployScript = Join-Path $RepoRoot "deploy_cableclub.ps1"
    if (-not (Test-Path $deployScript)) { throw "deploy_cableclub.ps1 not found at $deployScript" }

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
    $commitSha = git -C $RepoRoot rev-parse "$tagName^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $commitSha) {
        throw "Could not resolve tag '$tagName' to a commit in $RepoRoot -- has it been created yet? (Zip-Release.ps1's Tag step creates it)"
    }
    $commitSha = $commitSha.Trim()

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

function Wait-ForWorkflowRun([string]$Workflow, [string]$Repo, [DateTimeOffset]$Since) {
    Write-Step "Waiting for '$Workflow' on $Repo to start..."
    $runId = $null
    for ($i = 0; $i -lt 30; $i++) {
        $runs = & gh run list --workflow $Workflow --repo $Repo --limit 5 --json databaseId,createdAt | ConvertFrom-Json
        $match = $runs | Where-Object { [DateTimeOffset]$_.createdAt -ge $Since.AddSeconds(-5) } | Select-Object -First 1
        if ($match) { $runId = $match.databaseId; break }
        Start-Sleep -Seconds 2
    }
    if (-not $runId) { throw "Timed out waiting for a new run of '$Workflow' on $Repo to appear." }

    Write-Step "Watching run $runId ('$Workflow' on $Repo) until it completes..."
    & gh run watch $runId --repo $Repo --exit-status
    if ($LASTEXITCODE -ne 0) { throw "'$Workflow' on $Repo failed (run $runId, exit $LASTEXITCODE) -- see https://github.com/$Repo/actions/runs/$runId" }
}

function Publish-ToolsWebsite {
    if (-not (Test-StepEnabled 'ToolsWebsite')) { Write-Step "Skipping tools-website triggers"; return }

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "gh CLI not found on PATH. Install it and run 'gh auth login'."
    }

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
            $triggeredAt = [DateTimeOffset]::UtcNow
            & gh workflow run $target.Workflow --repo $target.Repo
            if ($LASTEXITCODE -ne 0) { throw "Failed to trigger '$($target.Workflow)' on $($target.Repo) (exit $LASTEXITCODE)" }

            # tectonic-tools' deploy reads tectonic-data's build output, so it
            # can't start until tectonic-data's run actually finishes -- wait
            # on every step but the last, where nothing downstream depends on it.
            if (-not $isLast) {
                Wait-ForWorkflowRun -Workflow $target.Workflow -Repo $target.Repo -Since $triggeredAt
            }
        }
    }
}

# ---- main ----

Publish-ToDrive
Publish-Shortlinks
Publish-VersionList
Publish-CableClubLive
Publish-ToolsWebsite

Write-Step "Done."
