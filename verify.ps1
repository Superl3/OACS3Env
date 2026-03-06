[CmdletBinding()]
param(
    [string]$ConfigRoot = "$HOME\\.config\\opencode",
    [switch]$RequireOpenCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RequiredOpenCodeVersion = "1.2.17"

function Show-Version {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Command
    )

    $resolved = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $resolved) {
        throw "$Name command not found: $Command"
    }

    $version = & $Command --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to read $Name version"
    }

    Write-Host ("{0}: {1}" -f $Name, ($version | Select-Object -First 1))
}

function Read-SemanticVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Command
    )

    $versionOutput = & $Command --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to read version for command: $Command"
    }

    $firstLine = ($versionOutput | Select-Object -First 1).ToString()
    $versionMatch = [regex]::Match($firstLine, '(?<!\d)(\d+\.\d+\.\d+(?:[-+][0-9A-Za-z\.-]+)?)')
    if (-not $versionMatch.Success) {
        throw "Failed to parse semantic version from: $firstLine"
    }

    return $versionMatch.Groups[1].Value
}

Show-Version -Name "winget" -Command "winget"
Show-Version -Name "git" -Command "git"
Show-Version -Name "node" -Command "node"
Show-Version -Name "python" -Command "python"
Show-Version -Name "bun" -Command "bun"

$opencodeCommand = Get-Command opencode -ErrorAction SilentlyContinue
if ($opencodeCommand) {
    Show-Version -Name "opencode" -Command "opencode"

    $opencodeVersion = Read-SemanticVersion -Command "opencode"
    if ($opencodeVersion -ne $RequiredOpenCodeVersion) {
        if ($RequireOpenCode) {
            throw "opencode version mismatch. Expected $RequiredOpenCodeVersion, found $opencodeVersion"
        }

        Write-Warning "opencode version mismatch. Expected $RequiredOpenCodeVersion, found $opencodeVersion. Continuing because -RequireOpenCode was not specified"
    }
}
elseif ($RequireOpenCode) {
    throw "opencode command not found: opencode"
}
else {
    Write-Warning "opencode is not installed; continuing because -RequireOpenCode was not specified"
}

$miseCommand = Get-Command mise -ErrorAction SilentlyContinue
if (-not $miseCommand) {
    throw "mise command not found"
}

Write-Host "mise current:"
mise current

$requiredPaths = @(
    (Join-Path $ConfigRoot "instructions"),
    (Join-Path $ConfigRoot "skills"),
    (Join-Path $ConfigRoot "opencode.json"),
    (Join-Path $ConfigRoot "agent/core/oac-vibe.md"),
    (Join-Path $ConfigRoot "agent/core/oac-strict.md"),
    (Join-Path $ConfigRoot "agent/core/oac-lite.md")
)

foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required config artifact: $path"
    }
    Write-Host "Found: $path"
}

Write-Host "PASS: Environment verification completed successfully."
