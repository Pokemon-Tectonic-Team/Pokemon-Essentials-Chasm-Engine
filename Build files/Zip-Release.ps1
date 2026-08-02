<#
.SYNOPSIS
    Builds the install and patch release zips, replacing "Chasm Zipper.jar".

.DESCRIPTION
    Bumps GAME_VERSION/DEV_VERSION, launches a PBS
    debug compile and waits for you to confirm it finished (Game.exe's debug
    console can't be captured reliably, see Invoke-GameCompile), tags the
    release, and produces both zips with forward-slash zip entry paths (so
    they extract correctly on Linux). All steps run by default; pass one or
    more -Only<Step> switches to isolate just those steps (e.g. to resume
    after a failure partway through, or to test one step). -DryRun logs
    every action without touching the repo or filesystem.

    This script is intentionally dependency-free so any dev can run it with
    nothing but PowerShell. Publishing the built zips (Drive upload, etc.)
    is a separate step — see Publish-Release.ps1.

.PARAMETER Version
    Release version in X.Y.Z form, e.g. 3.2.4.

.PARAMETER GameTitle
    Display name used in zip filenames. Downstream games should change the
    default below to their own name.

.EXAMPLE
    ./Zip-Release.ps1 -Version 3.2.4
.EXAMPLE
    ./Zip-Release.ps1 -Version 3.2.4 -DryRun
.EXAMPLE
    ./Zip-Release.ps1 -Version 3.2.4 -OnlyInstallZip -OnlyPatchZip
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$GameTitle = "Pokemon Tectonic",

    [switch]$Dev,

    [switch]$OnlyVersionBump,
    [switch]$OnlyCompile,
    [switch]$OnlyInstallZip,
    [switch]$OnlyPatchZip,
    [switch]$OnlyTag,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$BuildFilesDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $BuildFilesDir
$OutputDir = Join-Path $BuildFilesDir "Releases"

$versionParts = $Version.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]
$tagName = "v$Version"

$installZipName = "$GameTitle $Version.zip"
$patchZipName = "$GameTitle $major.$minor -- Patch $patch.zip"
$installZipPath = Join-Path $OutputDir $installZipName
$patchZipPath = Join-Path $OutputDir $patchZipName

$OnlySteps = @{
    VersionBump = $OnlyVersionBump
    Compile     = $OnlyCompile
    InstallZip  = $OnlyInstallZip
    PatchZip    = $OnlyPatchZip
    Tag         = $OnlyTag
}
$AnyOnlySet = @($OnlySteps.Values) -contains $true

function Test-StepEnabled([string]$Name) {
    if ($AnyOnlySet) { return $OnlySteps[$Name] }
    return $true
}

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-DryRun($msg) { Write-Host "[DryRun] $msg" -ForegroundColor Yellow }

function Update-GameVersion {
    $settingsPath = Join-Path $RepoRoot "Plugins/_Settings/GameSettings.rb"
    $devValue = if ($Dev) { 'true' } else { 'false' }

    if ($DryRun) {
        Write-DryRun "Would set GAME_VERSION = `"$Version`" and DEV_VERSION = $devValue in $settingsPath"
    }
    else {
        $content = Get-Content $settingsPath -Raw
        $content = $content -replace 'GAME_VERSION\s*=\s*"[^"]*"', "GAME_VERSION = `"$Version`""
        $content = $content -replace 'DEV_VERSION\s*=\s*(true|false)', "DEV_VERSION  = $devValue"
        Set-Content -Path $settingsPath -Value $content -NoNewline
    }
}

function Invoke-GameCompile {
    if (-not (Test-StepEnabled 'Compile')) { Write-Step "Skipping PBS compile"; return }
    if ($DryRun) { Write-DryRun "Would launch Game.exe debug compile and wait for manual confirmation"; return }

    Write-Step "Launching Game.exe debug compile..."
    $exePath = Join-Path $RepoRoot "Game.exe"
    if (-not (Test-Path $exePath)) { throw "Game.exe not found at $exePath" }

    # Game.exe's debug console is its own AllocConsole window; redirecting stdout from here
    # is unreliable (output never arrives, and it can crash the game with EBADF), so launch
    # it exactly like "Debug Game With PBS Compile.bat" does and confirm manually instead.
    $proc = Start-Process -FilePath $exePath -ArgumentList "debug", "compile" -WorkingDirectory $RepoRoot -PassThru

    Write-Host ""
    $response = Read-Host "Press Enter once the compile finished successfully (or type 'n' to abort)"
    if ($response -match '^(n|no)$') {
        if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        throw "PBS compile aborted by user."
    }

    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    Write-Step "Compile confirmed."
}

function Get-NanaZipConsolePath {
    $cmd = Get-Command 'NanaZipC.exe' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function New-ZipWithNanaZip {
    param([string[]]$Paths, [string]$OutputZipPath, [string]$NanaZipPath)

    $listFile = [System.IO.Path]::GetTempFileName()
    Push-Location $RepoRoot
    try {
        Set-Content -Path $listFile -Value $Paths -Encoding UTF8
        & $NanaZipPath a -tzip -mmt -y -scsUTF-8 "$OutputZipPath" "@$listFile" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "NanaZip exited with code $LASTEXITCODE" }
    }
    finally {
        Pop-Location
        Remove-Item $listFile -Force -ErrorAction SilentlyContinue
    }
}

function New-ZipWithDotNet {
    param([string[]]$Paths, [string]$OutputZipPath)

    $zip = [System.IO.Compression.ZipFile]::Open($OutputZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($relPath in $Paths) {
            $fullPath = Join-Path $RepoRoot $relPath
            if (Test-Path $fullPath -PathType Container) {
                Get-ChildItem -Path $fullPath -Recurse -File | ForEach-Object {
                    $entryName = $_.FullName.Substring($RepoRoot.Length + 1) -replace '\\', '/'
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
                }
            }
            else {
                $entryName = $relPath -replace '\\', '/'
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $fullPath, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}

function New-ZipFromRelativePaths {
    param([string[]]$Paths, [string]$OutputZipPath)

    if (Test-Path $OutputZipPath) { Remove-Item $OutputZipPath -Force }

    $existingPaths = @()
    foreach ($relPath in $Paths) {
        if (Test-Path (Join-Path $RepoRoot $relPath)) { $existingPaths += $relPath }
        else { Write-Warning "Path not found, skipping: $relPath" }
    }

    $nanaZipPath = Get-NanaZipConsolePath
    if ($nanaZipPath) {
        Write-Step "Using NanaZip ($nanaZipPath) for faster multi-threaded compression"
        New-ZipWithNanaZip -Paths $existingPaths -OutputZipPath $OutputZipPath -NanaZipPath $nanaZipPath
    }
    else {
        New-ZipWithDotNet -Paths $existingPaths -OutputZipPath $OutputZipPath
    }
}

function Get-DiffBaseTag {
    $existingTags = git -C $RepoRoot tag -l | Where-Object { $_ -match '^v?\d+\.\d+\.\d+$' }
    $baseVersion = if ($patch -gt 0) { "$major.$minor.0" } else { "$major.$($minor - 1).0" }
    $candidate = @("v$baseVersion", $baseVersion) | Where-Object { $existingTags -contains $_ } | Select-Object -First 1
    if (-not $candidate) {
        throw "Diff-base tag 'v$baseVersion' (or '$baseVersion') not found. Existing tags: $(if ($existingTags) { $existingTags -join ', ' } else { '(none)' })"
    }
    return $candidate
}

function Get-PatchFileList {
    param([string]$BaseTag)

    $installFilesListPath = Join-Path $BuildFilesDir "install_files.txt"
    $installEntries = Get-Content $installFilesListPath | Where-Object { $_.Trim() -ne '' }
    $installEntryPattern = ($installEntries | ForEach-Object { [regex]::Escape($_) }) -join '|'
    # Only files under an install_files.txt entry are shippable; without this filter,
    # a raw git diff pulls in dev-only paths like .github/
    $installFilter = "^($installEntryPattern)(/|$)"

    $diffFiles = git -C $RepoRoot diff --name-only "$BaseTag" HEAD |
    Where-Object {
        $_ -and (Test-Path (Join-Path $RepoRoot $_)) -and
        $_ -match $installFilter -and
        $_ -notmatch '^Plugins/'
    }
    return @($diffFiles) + @('Plugins') | Select-Object -Unique
}

function New-ReleaseTag {
    if (-not (Test-StepEnabled 'Tag')) { Write-Step "Skipping git tag"; return }
    if ($DryRun) { Write-DryRun "Would create and push tag $tagName"; return }
    Write-Step "Tagging release: $tagName"
    git -C $RepoRoot tag $tagName
    git -C $RepoRoot push origin $tagName
}

# ---- main ----

Write-Step "Releasing $GameTitle $Version (tag $tagName)$(if ($Dev) { ' [DEV]' })"

if (-not (Test-StepEnabled 'VersionBump')) { Write-Step "Skipping version bump" } else { Update-GameVersion }

Invoke-GameCompile

if (-not $DryRun) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

if (-not (Test-StepEnabled 'InstallZip')) {
    Write-Step "Skipping install zip"
}
else {
    $installFilesListPath = Join-Path $BuildFilesDir "install_files.txt"
    $installPaths = Get-Content $installFilesListPath | Where-Object { $_.Trim() -ne '' }
    if ($DryRun) {
        Write-DryRun "Would create install zip '$installZipName' from $($installPaths.Count) entries in install_files.txt"
    }
    else {
        Write-Step "Building install zip: $installZipName"
        New-ZipFromRelativePaths -Paths $installPaths -OutputZipPath $installZipPath
    }
}

if (-not (Test-StepEnabled 'PatchZip')) {
    Write-Step "Skipping patch zip"
}
else {
    try {
        $baseTag = Get-DiffBaseTag
        if ($DryRun) {
            $patchFiles = Get-PatchFileList -BaseTag $baseTag
            Write-DryRun "Would create patch zip '$patchZipName' diffing against $baseTag ($($patchFiles.Count) entries, Plugins/ included wholesale)"
        }
        else {
            $patchFiles = Get-PatchFileList -BaseTag $baseTag
            Write-Step "Building patch zip: $patchZipName (diff base: $baseTag)"
            New-ZipFromRelativePaths -Paths $patchFiles -OutputZipPath $patchZipPath
        }
    }
    catch {
        Write-Warning "Skipping patch zip: $_"
    }
}

New-ReleaseTag

Write-Step "Done."
