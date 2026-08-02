<#
.SYNOPSIS
    Builds the install and patch release zips, replacing "Chasm Zipper.jar".

.DESCRIPTION
    Bumps GAME_VERSION/DEV_VERSION and release_version.txt, runs a PBS debug
    compile, tags the release, and produces both zips with forward-slash zip
    entry paths (so they extract correctly on Linux). Each step can be
    skipped independently to test in isolation or resume after a failure,
    and -DryRun logs every action without touching the repo or filesystem.

.PARAMETER Version
    Release version in X.Y.Z form, e.g. 3.2.4.

.PARAMETER GameTitle
    Display name used in zip filenames. Downstream games should change the
    default below to their own name.

.EXAMPLE
    ./Release.ps1 -Version 3.2.4
.EXAMPLE
    ./Release.ps1 -Version 3.2.4 -DryRun
.EXAMPLE
    ./Release.ps1 -Version 3.2.4 -SkipCompile -SkipTag
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$GameTitle = "Pokemon Tectonic",

    [switch]$Dev,

    [switch]$SkipVersionBump,
    [switch]$SkipCompile,
    [switch]$SkipInstallZip,
    [switch]$SkipPatchZip,
    [switch]$SkipTag,

    [switch]$DryRun,

    [int]$CompileTimeoutSeconds = 300
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

    $releaseVersionPath = Join-Path $RepoRoot "release_version.txt"
    if ($DryRun) {
        Write-DryRun "Would write '$Version' to $releaseVersionPath"
    }
    else {
        Set-Content -Path $releaseVersionPath -Value $Version -NoNewline
    }
}

function Invoke-GameCompile {
    if ($SkipCompile) { Write-Step "Skipping PBS compile (-SkipCompile)"; return }
    if ($DryRun) { Write-DryRun "Would run 'Game.exe debug compile' and wait for the finished-compile signal"; return }

    Write-Step "Compiling PBS data (Game.exe debug compile)..."
    $exePath = Join-Path $RepoRoot "Game.exe"
    if (-not (Test-Path $exePath)) { throw "Game.exe not found at $exePath" }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exePath
    $psi.Arguments = "debug compile"
    $psi.WorkingDirectory = $RepoRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.Start() | Out-Null

    $finished = $false
    $deadline = (Get-Date).AddSeconds($CompileTimeoutSeconds)
    while (-not $proc.HasExited -and (Get-Date) -lt $deadline) {
        $line = $proc.StandardOutput.ReadLine()
        if ($null -eq $line) { continue }
        Write-Host $line
        if ($line -match '\*\*\* Finished full compile \*\*\*') { $finished = $true; break }
    }

    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }

    if (-not $finished) {
        throw "PBS compile did not report success within $CompileTimeoutSeconds s. Check the output above for legality errors."
    }
    Write-Step "Compile finished successfully."
}

function New-ZipFromRelativePaths {
    param([string[]]$Paths, [string]$OutputZipPath)

    if (Test-Path $OutputZipPath) { Remove-Item $OutputZipPath -Force }
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
            elseif (Test-Path $fullPath -PathType Leaf) {
                $entryName = $relPath -replace '\\', '/'
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $fullPath, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
            else {
                Write-Warning "Path not found, skipping: $relPath"
            }
        }
    }
    finally {
        $zip.Dispose()
    }
}

function Get-DiffBaseTag {
    $existingTags = git -C $RepoRoot tag -l "v*" | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' }
    $candidate = if ($patch -gt 0) { "v$major.$minor.0" } else { "v$major.$($minor - 1).0" }
    if ($existingTags -notcontains $candidate) {
        throw "Diff-base tag '$candidate' not found. Existing tags: $(if ($existingTags) { $existingTags -join ', ' } else { '(none)' })"
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
    if ($SkipTag) { Write-Step "Skipping git tag (-SkipTag)"; return }
    if ($DryRun) { Write-DryRun "Would create and push tag $tagName"; return }
    Write-Step "Tagging release: $tagName"
    git -C $RepoRoot tag $tagName
    git -C $RepoRoot push origin $tagName
}

# ---- main ----

Write-Step "Releasing $GameTitle $Version (tag $tagName)$(if ($Dev) { ' [DEV]' })"

if ($SkipVersionBump) { Write-Step "Skipping version bump (-SkipVersionBump)" } else { Update-GameVersion }

Invoke-GameCompile

if (-not $DryRun) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

if ($SkipInstallZip) {
    Write-Step "Skipping install zip (-SkipInstallZip)"
}
else {
    $installFilesListPath = Join-Path $BuildFilesDir "install_files.txt"
    $installPaths = Get-Content $installFilesListPath | Where-Object { $_.Trim() -ne '' }
    $installZipName = "$GameTitle $Version.zip"
    $installZipPath = Join-Path $OutputDir $installZipName
    if ($DryRun) {
        Write-DryRun "Would create install zip '$installZipName' from $($installPaths.Count) entries in install_files.txt"
    }
    else {
        Write-Step "Building install zip: $installZipName"
        New-ZipFromRelativePaths -Paths $installPaths -OutputZipPath $installZipPath
    }
}

if ($SkipPatchZip) {
    Write-Step "Skipping patch zip (-SkipPatchZip)"
}
else {
    try {
        $baseTag = Get-DiffBaseTag
        $patchZipName = "$GameTitle $major.$minor -- Patch $patch.zip"
        if ($DryRun) {
            $patchFiles = Get-PatchFileList -BaseTag $baseTag
            Write-DryRun "Would create patch zip '$patchZipName' diffing against $baseTag ($($patchFiles.Count) entries, Plugins/ included wholesale)"
        }
        else {
            $patchFiles = Get-PatchFileList -BaseTag $baseTag
            $patchZipPath = Join-Path $OutputDir $patchZipName
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
