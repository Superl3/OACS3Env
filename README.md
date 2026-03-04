# Environment Reproduction Scaffold

This repository captures the minimum artifacts needed to reproduce an OpenCode workstation setup.

## Included artifacts

- `winget-packages.json`: exported package manifest for `winget import`
- `opencode/`: snapshot of OpenCode config assets (`instructions`, `skills`, `opencode.json`)
- `.env.example`: example environment variables template
- `mise.toml`: pinned runtime tool versions
- `bootstrap.ps1`: setup script for package import, runtime install, and config restore
- `verify.ps1`: post-setup validation script

## Quick Start

1. Open PowerShell in this directory.
2. Run bootstrap:

```powershell
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

3. Run verification:

```powershell
pwsh -ExecutionPolicy Bypass -File .\verify.ps1
```

## Script usage

`bootstrap.ps1` options:

- `-ConfigRoot <path>`: target config root (default: `$HOME\.config\opencode`)
- `-SkipWingetImport`: skip `winget import`
- `-SkipConfigRestore`: skip restoring `opencode/` snapshot

Examples:

```powershell
pwsh -File .\bootstrap.ps1 -ConfigRoot "$HOME\.config\opencode"
pwsh -File .\bootstrap.ps1 -SkipWingetImport
pwsh -File .\verify.ps1 -ConfigRoot "$HOME\.config\opencode"
```

## Winget import note

`winget import` is best-effort. Some packages may be unavailable in current sources or may not match exact versions on a different machine. The script uses flags to continue past unavailable packages and version mismatches.

## Push to remote

After creating your repository and initial commit:

```bash
git remote add origin <REMOTE_URL>
git push -u origin main
```
