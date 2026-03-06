[CmdletBinding()]
param(
    [string]$ConfigRoot = "$HOME\\.config\\opencode",
    [switch]$SkipWingetImport,
    [switch]$SkipConfigRestore,
    [switch]$InstallOpenCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$OpenCodePackageId = "SST.opencode"
$OpenCodePinnedVersion = "1.2.17"
$RequiredSnapshotArtifacts = @(
    "opencode.json",
    "instructions",
    "skills",
    "agent/core/oac-vibe.md",
    "agent/core/oac-strict.md",
    "agent/core/oac-lite.md"
)

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
        [Parameter(Mandatory = $true)][string]$PackageId,
        [string]$Version
    )

    $installArgs = @(
        "install",
        "--id", $PackageId,
        "--exact",
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--disable-interactivity"
    )

    if ($Version) {
        $installArgs += @("--version", $Version)
    }

    & $script:WingetPath @installArgs

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

function Read-SemanticVersion {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName
    )

    $commandPath = Resolve-CommandPath -CommandName $CommandName
    if (-not $commandPath) {
        return $null
    }

    $versionOutput = & $commandPath --version 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $versionOutput) {
        return $null
    }

    $firstLine = ($versionOutput | Select-Object -First 1).ToString()
    $versionMatch = [regex]::Match($firstLine, '(?<!\d)(\d+\.\d+\.\d+(?:[-+][0-9A-Za-z\.-]+)?)')
    if ($versionMatch.Success) {
        return $versionMatch.Groups[1].Value
    }

    return $null
}

function Ensure-OpenCode {
    param(
        [Parameter(Mandatory = $true)][string]$PackageId,
        [Parameter(Mandatory = $true)][string]$PinnedVersion
    )

    $existingVersion = Read-SemanticVersion -CommandName "opencode"
    if ($existingVersion -eq $PinnedVersion) {
        Write-Step "opencode is already pinned at version $PinnedVersion"
        return (Resolve-CommandPath -CommandName "opencode")
    }

    if ($existingVersion) {
        Write-Step "opencode version '$existingVersion' detected; reinstalling pinned version $PinnedVersion"
    }
    else {
        Write-Step "opencode not found; installing pinned version $PinnedVersion"
    }

    Install-WingetPackage -PackageId $PackageId -Version $PinnedVersion
    Refresh-ProcessPath

    $opencodePath = Resolve-CommandPath -CommandName "opencode"
    if (-not $opencodePath) {
        throw "opencode command is not available after installing pinned version $PinnedVersion"
    }

    $finalVersion = Read-SemanticVersion -CommandName "opencode"
    if ($finalVersion -ne $PinnedVersion) {
        throw "opencode version check failed. Expected '$PinnedVersion', found '$finalVersion'"
    }

    Write-Step "opencode pinned version verified: $finalVersion"
    return $opencodePath
}

function Assert-RequiredArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    foreach ($artifact in $RequiredSnapshotArtifacts) {
        $artifactPath = Join-Path $RootPath $artifact
        if (-not (Test-Path -LiteralPath $artifactPath)) {
            throw "Missing required config artifact in ${Label}: $artifactPath"
        }
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
Write-Step "When opted in, opencode is pinned to version $OpenCodePinnedVersion"

$gitPath = Ensure-Tool -CommandName "git" -PackageId "Git.Git"
$misePath = Ensure-Tool -CommandName "mise" -PackageId "jdx.mise"

$opencodePath = $null
if ($InstallOpenCode) {
    Write-Step "-InstallOpenCode specified; ensuring pinned opencode version $OpenCodePinnedVersion"
    $opencodePath = Ensure-OpenCode -PackageId $OpenCodePackageId -PinnedVersion $OpenCodePinnedVersion
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

    Assert-RequiredArtifacts -RootPath $snapshotRoot -Label "snapshot source"

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
        Assert-RequiredArtifacts -RootPath $ConfigRoot -Label "restored ConfigRoot"
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
