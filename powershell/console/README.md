# PowerShell Console Utility

The PowerShell console utility provides small colored output helpers for readable scripts.

## Functions

- `Show-Section` - prints a section heading.
- `Show-Info` - prints an informational message.
- `Show-Success` - prints a success message.
- `Show-Warning` - prints a warning message.
- `Show-Error` - prints an error message.
- `Show-Break` - prints a blank line.
- `Show-Banner` - prints a large script title banner with top and bottom separators.
- `Show-Choices` - displays a numbered list of choices.
- `Read-Choice` - prompts until the user selects a valid choice.
- `Read-Text` - prompts for text input with optional default and required validation.
- `Read-Confirm` - prompts for a yes/no confirmation.

## Usage

```powershell
. ..\bootstrap.ps1 -Imports Console

Show-Section "Install"
Show-Info "Downloading files"
Show-Success "Install complete"
Show-Warning "Optional setting was skipped"
Show-Error "Something failed"
Show-Break
```

Display a script banner:

```powershell
Show-Banner "Apps Shortcut Sync Tool"
Show-Banner "Drive Setup" -Subtitle "Environment variables" -Width 72 -Color Magenta
```

Prompt for choices:

```powershell
$action = Read-Choice -Prompt "Choose an action" -Choices @("Install", "Update", "Exit") -Default "Install"

if (Read-Confirm -Prompt "Continue?" -Default Yes) {
    Show-Success "Continuing"
}
```

From GitHub raw:

```powershell
. ([scriptblock]::Create((Invoke-WebRequest "https://raw.githubusercontent.com/poziel/dev-utils/refs/heads/main/powershell/bootstrap.ps1" -UseBasicParsing).Content)) -Imports Console
```

Multiple imports can be requested with the same parameter as more PowerShell utilities are added:

```powershell
. ([scriptblock]::Create((Invoke-WebRequest "https://raw.githubusercontent.com/poziel/dev-utils/refs/heads/main/powershell/bootstrap.ps1" -UseBasicParsing).Content)) -Imports Console
```

Emoji prefixes are optional:

```powershell
Show-Success "Install complete" -UseEmoji
```

## Bootstrap Behavior

`bootstrap.ps1` accepts an `-Imports` parameter:

```powershell
. .\bootstrap.ps1 -Imports Console
```

When called, it:

1. Resolves `Console` to `powershell/console/bootstrap.ps1`.
2. Downloads the console plugin bootstrap from GitHub raw.
3. The console plugin bootstrap downloads and dot-sources its helper files.
4. The `Show-*` functions remain available in the current PowerShell session.

When used locally, `powershell/console/bootstrap.ps1` can also be dot-sourced directly:

```powershell
. .\bootstrap.ps1
```

## Implementation Philosophy

This plugin has no dependencies and uses plain PowerShell functions so it can run on PowerShell 5+ and stay easy to reuse in setup scripts. Files are split by purpose:

- `messages.ps1` - status messages and spacing.
- `banner.ps1` - script title banners.
- `prompts.ps1` - interactive choices, text input, and confirmations.
