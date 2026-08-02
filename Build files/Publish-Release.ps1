<#
.SYNOPSIS
    Uploads built release zips to Google Drive via rclone.

.DESCRIPTION
    Separate from Release.ps1 on purpose: Release.ps1 stays dependency-free
    so any dev can build a release zip with nothing but PowerShell, while
    this script carries the extra setup cost of installing and configuring
    rclone (see README) and is only expected to be run by whoever is
    actually publishing a release.

    -DryRun passes rclone's own --dry-run flag through, so it still
    authenticates and contacts the Drive folder and reports what it would
    upload without writing anything — a missing rclone install, bad
    credentials, or a wrong folder ID will surface as a real error here,
    not just get logged and skipped.

.PARAMETER Version
    Release version in X.Y.Z form, e.g. 3.2.4. Used to locate the zips built
    by Release.ps1 in Releases/ — must match the -Version it was run with.

.PARAMETER GameTitle
    Display name used in zip filenames. Must match what Release.ps1 was run
    with.

.PARAMETER DriveFolderId
    Google Drive folder ID to upload into (the id in the folder's share
    link). Defaults to the shared Pokemon Tectonic releases folder;
    downstream games should override.

.PARAMETER RcloneRemote
    Name of the rclone remote to upload through. Each publisher runs
    `rclone config` once to create a remote with this name, authorized
    against their own Google account (see README).

.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4
.EXAMPLE
    ./Publish-Release.ps1 -Version 3.2.4 -DryRun
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [string]$GameTitle = "Pokemon Tectonic",

    [string]$DriveFolderId = "1ZkpLqyPlt8fqeff9kqFWYBcIpzwESE8_",
    [string]$RcloneRemote = "gdrive",

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$BuildFilesDir = $PSScriptRoot
$OutputDir = Join-Path $BuildFilesDir "Releases"

$versionParts = $Version.Split('.')
$major = [int]$versionParts[0]
$minor = [int]$versionParts[1]
$patch = [int]$versionParts[2]

$installZipPath = Join-Path $OutputDir "$GameTitle $Version.zip"
$patchZipPath = Join-Path $OutputDir "$GameTitle $major.$minor -- Patch $patch.zip"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    throw "rclone not found on PATH. Install it and run 'rclone config' to create a remote named '$RcloneRemote' authorized against your Google account (see README)."
}

$zipsToUpload = @($installZipPath, $patchZipPath) | Where-Object { Test-Path $_ }
if (-not $zipsToUpload) {
    throw "No release zips found in $OutputDir matching version $Version. Run Release.ps1 first."
}

foreach ($zipPath in $zipsToUpload) {
    $zipName = Split-Path -Leaf $zipPath
    Write-Step "$(if ($DryRun) { '[DryRun] ' })Uploading $zipName to Drive folder $DriveFolderId..."
    $rcloneArgs = @('copy', $zipPath, "${RcloneRemote}:", '--drive-root-folder-id', $DriveFolderId, '--progress')
    if ($DryRun) { $rcloneArgs += '--dry-run' }
    & rclone @rcloneArgs
    if ($LASTEXITCODE -ne 0) { throw "rclone upload failed for $zipName (exit $LASTEXITCODE)" }
}

Write-Step "Done."
