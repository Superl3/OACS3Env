[CmdletBinding()]
param(
    [string]$ConfigRoot = "$HOME\\.config\\opencode",
    [switch]$SkipWingetImport,
    [switch]$SkipConfigRestore,
    [switch]$InstallOpenCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathParts = @()

    if ($machinePath) {
        $pathParts += $machinePath
    }

    if ($userPath) {
        $pathParts += $userPath
    }

    $env:Path = ($pathParts -join ";")
}

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        if ($command.Path) {
            return $command.Path
        }

        if ($command.Definition -and (Test-Path -LiteralPath $command.Definition)) {
            return $command.Definition
        }
    }

    $fallbackPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\$CommandName.exe"
    if (Test-Path -LiteralPath $fallbackPath) {
        return $fallbackPath
    }

    return $null
}

$script:WingetPath = Resolve-CommandPath -CommandName "winget"
if (-not $script:WingetPath) {
    throw "winget command was not found. Install/repair App Installer, open a new PowerShell session, and retry."
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PackageId
    )

    & $script:WingetPath install `
        --id $PackageId `
        --exact `
        --accept-source-agreements `
        --accept-package-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "winget install failed for '$PackageId' (exit code: $LASTEXITCODE)"
    }
}

function Ensure-Tool {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$PackageId
    )

    $commandPath = Resolve-CommandPath -CommandName $CommandName
    if ($commandPath) {
        return $commandPath
    }

    Write-Step "$CommandName not found; installing $PackageId"
    Install-WingetPackage -PackageId $PackageId

    Refresh-ProcessPath
    $commandPath = Resolve-CommandPath -CommandName $CommandName

    if (-not $commandPath) {
        throw "$CommandName is still not available after installing $PackageId"
    }

    return $commandPath
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
        & $script:WingetPath import `
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

Write-Step "Default tool policy: ensure git and mise only; opencode install is opt-in via -InstallOpenCode"

$gitPath = Ensure-Tool -CommandName "git" -PackageId "Git.Git"
$misePath = Ensure-Tool -CommandName "mise" -PackageId "jdx.mise"

$opencodePath = $null
if ($InstallOpenCode) {
    Write-Step "-InstallOpenCode specified; ensuring opencode"
    $opencodePath = Ensure-Tool -CommandName "opencode" -PackageId "SST.opencode"
}
else {
    Write-Step "Skipping opencode installation by default"
}

Write-Step "Resolved git command path: $gitPath"
if ($opencodePath) {
    Write-Step "Resolved opencode command path: $opencodePath"
}

Write-Step "Trusting and installing mise tools"
Push-Location $repoRoot
try {
    & $misePath trust "$repoRoot"
    & $misePath install
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
