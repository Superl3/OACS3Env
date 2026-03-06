# Environment Reproduction Scaffold

This repository captures the minimum artifacts needed to reproduce an OpenCode workstation setup.

## Included artifacts

- `winget-packages.json`: curated minimal manifest for `winget import`
- `opencode/`: snapshot of OpenCode config assets (`instructions`, `skills`, `opencode.json`)
- `.env.example`: example environment variables template
- `mise.toml`: pinned runtime tool versions
- `bootstrap.ps1`: setup script for package import, runtime install, and config restore
- `verify.ps1`: post-setup validation script

## Minimal package strategy

`winget-packages.json` intentionally tracks only three packages needed to reproduce OpenCode setup:

- `Git.Git`
- `jdx.mise`
- `SST.opencode`

Everything else is installed through `mise install` and restored from `opencode/` snapshot files. Personal apps, games, and `msstore` entries are intentionally excluded.

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
- `-SkipWingetImport`: skip `winget import` (the script still checks for `git`, `mise`, and `opencode` and tries to install any missing required tool individually)
- `-SkipConfigRestore`: skip restoring `opencode/` snapshot

Examples:

```powershell
pwsh -File .\bootstrap.ps1 -ConfigRoot "$HOME\.config\opencode"
pwsh -File .\bootstrap.ps1 -SkipWingetImport
pwsh -File .\verify.ps1 -ConfigRoot "$HOME\.config\opencode"
```

## Winget import note

`winget import` is best-effort and targets only the three required packages. The bootstrap script also checks for `git`, `mise`, and `opencode` and installs any missing required tool.

## Minimal reproduction path

1. Install required packages with `winget import` from `winget-packages.json`.
2. Install pinned runtimes with `mise trust` + `mise install`.
3. Restore OpenCode config from `opencode/` snapshot.

## Push to remote

After creating your repository and initial commit:

```bash
git remote add origin <REMOTE_URL>
git push -u origin main
```
