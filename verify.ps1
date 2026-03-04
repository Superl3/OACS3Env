[CmdletBinding()]
param(
    [string]$ConfigRoot = "$HOME\\.config\\opencode"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

Show-Version -Name "winget" -Command "winget"
Show-Version -Name "git" -Command "git"
Show-Version -Name "node" -Command "node"
Show-Version -Name "python" -Command "python"
Show-Version -Name "bun" -Command "bun"
Show-Version -Name "opencode" -Command "opencode"

$miseCommand = Get-Command mise -ErrorAction SilentlyContinue
if (-not $miseCommand) {
    throw "mise command not found"
}

Write-Host "mise current:"
mise current

$requiredPaths = @(
    (Join-Path $ConfigRoot "instructions"),
    (Join-Path $ConfigRoot "skills"),
    (Join-Path $ConfigRoot "opencode.json")
)

foreach ($path in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required config artifact: $path"
    }
    Write-Host "Found: $path"
}

Write-Host "PASS: Environment verification completed successfully."
