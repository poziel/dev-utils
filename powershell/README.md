# PowerShell Utilities

This folder contains lightweight PowerShell helper utilities for scripts, setup tasks, automation, and CLI workflows.

## Available Utilities

- `console` - colored output, script banners, prompts, and menus with key-based actions.
- `environment` - helpers for User environment variables, drive-label lookup, and path normalization.

## Bootstrap Usage

Dot-source the bootstrap file and tell it what to import:

```powershell
. .\bootstrap.ps1 -Imports Console,Environment

Show-Section "Setup"
Show-Info "Checking environment"
$scoopRoot = Get-RequiredEnvironmentVariable -Name "SCOOP_ROOT"
Show-Success "Ready"
```

From GitHub raw:

```powershell
. ([scriptblock]::Create((Invoke-WebRequest "https://raw.githubusercontent.com/poziel/dev-utils/refs/heads/main/powershell/bootstrap.ps1" -UseBasicParsing).Content)) -Imports Console,Environment
```

The bootstrap script loads each requested plugin's own `bootstrap.ps1` from GitHub raw. The plugin bootstrap decides which files belong to that plugin.

## Architecture

PowerShell utilities use standalone functions instead of modules, classes, or framework-style conventions. This keeps scripts easy to dot-source, inspect, and copy into standalone automation when needed.

The root bootstrap does not hardcode individual script files. It maps import names to plugin folders:

```txt
-Imports Console -> powershell/console/bootstrap.ps1
-Imports Environment -> powershell/environment/bootstrap.ps1
```

Each plugin folder owns its own entrypoint and can grow internally without changing the root bootstrap.

## Extension Philosophy

Add new utilities only when they solve a real repeated scripting problem. Keep each utility small, dependency-free, and documented with direct usage examples.
