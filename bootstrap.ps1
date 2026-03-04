[CmdletBinding()]
param(
    [string]$ConfigRoot = "$HOME\\.config\\opencode",
    [switch]$SkipWingetImport,
    [switch]$SkipConfigRestore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wingetManifest = Join-Path $repoRoot "winget-packages.json"
$snapshotRoot = Join-Path $repoRoot "opencode"

if (-not $SkipWingetImport) {
    if (-not (Test-Path -LiteralPath $wingetManifest)) {
        throw "winget manifest not found: $wingetManifest"
    }

    Write-Step "Importing packages from winget-packages.json (best-effort)"
    winget import `
        --import-file "$wingetManifest" `
        --accept-source-agreements `
        --accept-package-agreements `
        --ignore-unavailable `
        --ignore-versions `
        --disable-interactivity
}
else {
    Write-Step "Skipping winget import"
}

if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    Write-Step "mise not found; installing via winget"
    winget install `
        --id jdx.mise `
        --exact `
        --accept-source-agreements `
        --accept-package-agreements `
        --disable-interactivity
}

$miseCommand = Get-Command mise -ErrorAction SilentlyContinue
if (-not $miseCommand) {
    throw "mise is still not available in PATH. Open a new shell and rerun bootstrap.ps1."
}

Write-Step "Trusting and installing mise tools"
mise trust "$repoRoot"
mise install

if (-not $SkipConfigRestore) {
    if (-not (Test-Path -LiteralPath $snapshotRoot)) {
        throw "opencode snapshot not found: $snapshotRoot"
    }

    if (Test-Path -LiteralPath $ConfigRoot) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$ConfigRoot.backup.$timestamp"
        Write-Step "Backing up existing ConfigRoot to: $backupPath"
        Move-Item -LiteralPath $ConfigRoot -Destination $backupPath
    }

    $configParent = Split-Path -Parent $ConfigRoot
    if (-not (Test-Path -LiteralPath $configParent)) {
        New-Item -ItemType Directory -Path $configParent -Force | Out-Null
    }

    Write-Step "Restoring opencode snapshot to ConfigRoot"
    Copy-Item -LiteralPath $snapshotRoot -Destination $ConfigRoot -Recurse -Force
}
else {
    Write-Step "Skipping config snapshot restore"
}

Write-Host "Bootstrap completed successfully."
