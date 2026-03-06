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

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PackageId
    )

    winget install `
        --id $PackageId `
        --exact `
        --accept-source-agreements `
        --accept-package-agreements `
        --disable-interactivity
}

function Ensure-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$PackageId
    )

    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        return
    }

    Write-Step "$CommandName not found; installing $PackageId"
    Install-WingetPackage -PackageId $PackageId

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        throw "$CommandName is still not available after installing $PackageId"
    }
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wingetManifest = Join-Path $repoRoot "winget-packages.json"
$snapshotRoot = Join-Path $repoRoot "opencode"

if (-not $SkipWingetImport) {
    if (-not (Test-Path -LiteralPath $wingetManifest)) {
        throw "winget manifest not found: $wingetManifest"
    }

    Write-Step "Importing packages from winget-packages.json (best-effort)"
    try {
        winget import `
            --import-file "$wingetManifest" `
            --accept-source-agreements `
            --accept-package-agreements `
            --ignore-unavailable `
            --ignore-versions `
            --disable-interactivity

        if ($LASTEXITCODE -ne 0) {
            Write-Step "winget import reported issues; continuing with required tool checks"
        }
    }
    catch {
        Write-Step "winget import failed; continuing with required tool checks"
    }
}
else {
    Write-Step "Skipping winget import"
}

Ensure-Tool -CommandName "git" -PackageId "Git.Git"
Ensure-Tool -CommandName "mise" -PackageId "jdx.mise"
Ensure-Tool -CommandName "opencode" -PackageId "SST.opencode"

$miseCommand = Get-Command mise -ErrorAction SilentlyContinue
if (-not $miseCommand) {
    throw "mise is still not available in PATH. Open a new shell and rerun bootstrap.ps1."
}

Write-Step "Trusting and installing mise tools"
Push-Location $repoRoot
try {
    mise trust "$repoRoot"
    mise install
}
finally {
    Pop-Location
}

if (-not $SkipConfigRestore) {
    if (-not (Test-Path -LiteralPath $snapshotRoot)) {
        throw "opencode snapshot not found: $snapshotRoot"
    }

    $backupPath = $null
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
    try {
        Copy-Item -LiteralPath $snapshotRoot -Destination $ConfigRoot -Recurse -Force
    }
    catch {
        $restoreError = $_

        if ($backupPath -and (Test-Path -LiteralPath $backupPath)) {
            Write-Step "Restore failed; attempting to roll back ConfigRoot from backup"

            try {
                if (Test-Path -LiteralPath $ConfigRoot) {
                    Remove-Item -LiteralPath $ConfigRoot -Recurse -Force
                }

                Move-Item -LiteralPath $backupPath -Destination $ConfigRoot
            }
            catch {
                Write-Step "Rollback from backup failed: $($_.Exception.Message)"
            }
        }

        throw $restoreError
    }
}
else {
    Write-Step "Skipping config snapshot restore"
}

Write-Host "Bootstrap completed successfully."
