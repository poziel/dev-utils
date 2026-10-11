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
- `Wait-Continue` - waits for Enter, with a customizable message.
- `Show-Menu` - displays a script title, description, and keyed actions; Q quits the menu.

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

## Script Menus

Try the local demo from the repository root:

```powershell
pwsh -NoProfile -File .\powershell\console\examples\menu.ps1
```

Use `powershell.exe` instead of `pwsh` for Windows PowerShell 5.1. The demo uses only local helpers and harmless sample actions. Try 1, 2, and 4, pressing Enter after each action to return to the menu. Try an invalid key such as 3, then Q to quit. Add `-ReadLine` to also require Enter when selecting an option.

Load the Console plugin once, then call `Show-Menu` at the end of your script after defining its functions. For a local checkout, dot-source the plugin directly:

```powershell
. "D:\Dev\1-codes\dev-utils\powershell\console\bootstrap.ps1"

Show-Menu -Title "My Setup Script" -Description "Install, update, and check your tools." -Options @(
    @{ Key = "1"; Label = "Install tools"; Action = { Show-Info "Installing tools" } }
    @{ Key = "2"; Label = "Update tools"; Action = { Show-Info "Updating tools" } }
    @{ Key = "4"; Label = "Check status"; Action = { Show-Success "Everything is ready" } }
)
```

Replace the example actions with your own commands, function calls, or script calls such as `& "$PSScriptRoot\install.ps1"`. Actions are scriptblocks, so one option can run several commands.

- Press a key immediately; Enter is not required. Keys are case-insensitive.
- Options appear in the order supplied. Each key must be a unique single letter or digit; numbers can be skipped.
- `Q) Quit` is added automatically. Q returns from the menu; execution continues after `Show-Menu`. Pass `-AllowQuit $false` to hide and disable the built-in quit option. In that mode Q is an ordinary key and only runs an action if you define one for it.
- Two blank lines separate the last option from the prompt. Invalid input redraws the menu and replaces the second blank line with one red hint, such as `Press 1, 2, 4, or Q to quit.` The hint always uses your actual keys and has no logging prefix.
- The screen is cleared before showing the menu and before running an action.
- After an action finishes, its output remains on screen until the user presses Enter. The pause message has no trailing colon. The screen is then cleared and the menu returns.
- Actions run in a child scope, can read caller variables, and display their output. Terminating errors propagate to the calling script.
- Use `-ReadLine` in hosts that cannot read individual keypresses. In that mode, type a key and press Enter.

The GitHub raw import above also loads menus. To test local changes, use the direct local plugin bootstrap shown here.

`-Description` is your script's explanatory text; it can contain multiple lines. The helper does not add instructions to that text. For a simple script without a menu, use `Show-Banner`, your own description, and `Wait-Continue` wherever a pause is needed:

```powershell
Show-Banner "Setup Tool"
Show-Info "This script prepares your development tools."
# Run your commands here.
Wait-Continue  # Press Enter to continue
```

## Script Arguments and Direct Actions

The [demo](examples/menu.ps1) is also a template for accepting arguments. From the repository root:

```powershell
# Run option 2 directly, using its default task name; no menu, clearing, or pause.
.\powershell\console\examples\menu.ps1 -Action Task

# Run the same action with an argument.
.\powershell\console\examples\menu.ps1 -Action Task -TaskName "Build tools"

# Open the menu; option 2 will use this task name.
.\powershell\console\examples\menu.ps1 -TaskName "Build tools"

# Inspect accepted parameters and examples.
Get-Help .\powershell\console\examples\menu.ps1 -Full
```

Declare parameters at the top of your own script, before importing helpers or running commands:

```powershell
[CmdletBinding(PositionalBinding = $false)]
param(
    [ValidateSet("Hello", "Task", "Status")]
    [string]$Action,

    [ValidateNotNullOrEmpty()]
    [string]$TaskName = "Sample task"
)
```

PowerShell handles argument binding: `CmdletBinding` rejects unknown parameter names, `PositionalBinding = $false` rejects stray positional values, and `ValidateSet` rejects unsupported actions. Defaults apply when a parameter is omitted. Add comment-based `.PARAMETER` help as in the demo to describe what each parameter accepts.

After importing helpers and defining your actions, check `$PSBoundParameters.ContainsKey("Action")`. If supplied, run that action and `return` before calling `Show-Menu`. The demo shares its action scriptblocks between both paths so they execute the same code. Supplying `TaskName` alone configures the interactive action without selecting it.

Pass arguments inside an action using normal PowerShell calls:

```powershell
@{ Key = "2"; Label = "Build tools"; Action = { Invoke-Build -Name $TaskName } }

# Call another PowerShell script with named arguments.
@{ Key = "4"; Label = "Run setup"; Action = { & "$PSScriptRoot\setup.ps1" -Action Install -Target "Tools" } }
```

The called script must declare those parameters. For an executable, use its own argument syntax, for example `& git -C $projectPath status`. That executable is responsible for validating its arguments.

## Additional Usage

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
- `menus.ps1` - reusable script menus and single-key input.
