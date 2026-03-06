# Environment Reproduction Scaffold

This repository captures the minimum artifacts needed to reproduce an OpenCode workstation setup.

## Included artifacts

- `winget-packages.json`: curated minimal manifest for `winget import`
- `opencode/`: snapshot of OpenCode config assets (`instructions`, `skills`, `opencode.json`, `agent/core` profiles)
- `.env.example`: example environment variables template
- `mise.toml`: pinned runtime tool versions
- `bootstrap.ps1`: setup script for package import, runtime install, and config restore
- `verify.ps1`: post-setup validation script

## Minimal package strategy

`winget-packages.json` intentionally tracks only two baseline packages:

- `Git.Git`
- `jdx.mise`

`SST.opencode` is not part of the default manifest and is not installed automatically unless you opt in.

If you opt in with `-InstallOpenCode`, bootstrap enforces a pinned `opencode` version (`1.2.17`).

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
- `-SkipWingetImport`: skip `winget import` (the script still checks for `git` and `mise` and installs any missing required tool individually)
- `-SkipConfigRestore`: skip restoring `opencode/` snapshot
- `-InstallOpenCode`: opt in to install `opencode` (`SST.opencode`) via winget, pinned to `1.2.17`

`verify.ps1` options:

- `-ConfigRoot <path>`: target config root (default: `$HOME\.config\opencode`)
- `-RequireOpenCode`: require `opencode` to be present; fail if missing

Examples:

```powershell
pwsh -File .\bootstrap.ps1 -ConfigRoot "$HOME\.config\opencode"
pwsh -File .\bootstrap.ps1 -SkipWingetImport
pwsh -File .\bootstrap.ps1 -InstallOpenCode
pwsh -File .\verify.ps1 -ConfigRoot "$HOME\.config\opencode"
pwsh -File .\verify.ps1 -RequireOpenCode
```

## Winget import note

`winget import` is best-effort and targets only `Git.Git` and `jdx.mise`. The bootstrap script also checks for `git` and `mise` and installs any missing required tool. `opencode` is opt-in with `-InstallOpenCode` and is pinned to `1.2.17` when installed.

The snapshot restore now requires and validates the Vibe/Strict/Query profile files:

- `opencode/agent/core/oac-vibe.md`
- `opencode/agent/core/oac-strict.md`
- `opencode/agent/core/oac-lite.md`

`verify.ps1` checks these same profile artifacts under `ConfigRoot`.

## Troubleshooting: `mise` not found right after install

Symptom:

- Bootstrap reports `mise command not found`, or `mise` is still not recognized immediately after install.

Actions:

1. Open a new PowerShell session in this repository directory.
2. Refresh package sources and reinstall `mise` explicitly:

```powershell
winget source update
winget install --id jdx.mise --exact --accept-source-agreements --accept-package-agreements --disable-interactivity
```

3. Run bootstrap again:

```powershell
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

## Troubleshooting: Defender flags `opencode`

If Defender blocks automatic install, keep the baseline setup and add `opencode` manually after review:

```powershell
winget install --id SST.opencode --exact --version 1.2.17 --accept-source-agreements --accept-package-agreements --disable-interactivity
pwsh -ExecutionPolicy Bypass -File .\verify.ps1 -RequireOpenCode
```

## Minimal reproduction path

1. Install baseline packages with `winget import` from `winget-packages.json`.
2. Install pinned runtimes with `mise trust` + `mise install`.
3. Restore OpenCode config from `opencode/` snapshot.
4. Optional: install `opencode` with `bootstrap.ps1 -InstallOpenCode` and validate with `verify.ps1 -RequireOpenCode`.

## Push to remote

After creating your repository and initial commit:

```bash
git remote add origin <REMOTE_URL>
git push -u origin main
```
