# PowerShell Environment Utility

The Environment utility provides small helpers for reset/setup scripts that depend on drive labels, User environment variables, and path construction.

## Functions

- `Get-UserEnvironmentVariable` - reads a User environment variable.
- `Get-RequiredEnvironmentVariable` - reads an environment variable and throws when missing.
- `Set-UserEnvironmentVariable` - persists a User environment variable and updates the current session.
- `Get-DriveLetterByLabel` - resolves a mounted drive by volume label.
- `Normalize-DriveInput` - validates and normalizes drive-letter input.
- `Resolve-PathFromDrive` - joins a drive letter with a relative path.
- `Convert-ToGitPath` - converts Windows backslashes to forward slashes for Git config values.

## Usage

```powershell
. ..\bootstrap.ps1 -Imports Console,Environment

$scoopRoot = Get-RequiredEnvironmentVariable -Name "SCOOP_ROOT"
Set-UserEnvironmentVariable -Name "GIT_CONFIG_GLOBAL" -Value "$scoopRoot\config\git\.gitconfig"
```

## Philosophy

These helpers are intentionally plain functions. They avoid config files and framework-style abstractions so setup scripts remain readable and easy to repair after a Windows reset.
