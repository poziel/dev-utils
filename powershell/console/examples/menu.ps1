<#
.SYNOPSIS
Runs a local menu demo with harmless sample actions.

.DESCRIPTION
Shows a menu when Action is omitted. Supply Action to run once without clearing
the screen or waiting for input. TaskName is used by the task in either mode.

.PARAMETER Action
Action to run directly: Hello, Task, or Status. Omit to open the menu.

.PARAMETER TaskName
Name displayed by the sample task. Defaults to "Sample task".

.PARAMETER ReadLine
Requires Enter after menu choices for hosts without single-key input support.

.EXAMPLE
pwsh -NoProfile -File .\menu.ps1

.EXAMPLE
powershell.exe -NoProfile -File .\menu.ps1 -ReadLine

.EXAMPLE
pwsh -NoProfile -File .\menu.ps1 -Action Task -TaskName "My task"
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [ValidateSet("Hello", "Task", "Status")]
    [string]$Action,

    [ValidateNotNullOrEmpty()]
    [string]$TaskName = "Sample task",

    [switch]$ReadLine
)

. (Join-Path $PSScriptRoot "..\bootstrap.ps1")

# The same actions are used by the menu and direct command-line execution.
function Invoke-DemoTask {
    param([string]$Name = "Sample task")

    Show-Section $Name
    Show-Info "Starting..."
    Start-Sleep -Milliseconds 600
    Show-Info "Working..."
    Start-Sleep -Milliseconds 600
    Show-Success "Done!"
}

$demoActions = @{
    Hello = { Show-Success "Hello! You selected the greeting action." }
    Task = { Invoke-DemoTask -Name $TaskName }
    Status = {
        Show-Section "Your session"
        Show-Info "PowerShell version: $($PSVersionTable.PSVersion)"
        Show-Info "Current folder: $((Get-Location).Path)"
    }
}

if ($PSBoundParameters.ContainsKey("Action")) {
    & $demoActions[$Action]
    return
}

Show-Menu -Title "Menu Demo" -Description "Run a sample task or inspect your PowerShell session. This demo makes no system changes." -ReadLine:$ReadLine -Options @(
    @{
        Key = "1"
        Label = "Say hello"
        Action = $demoActions.Hello
    }
    @{
        Key = "2"
        Label = "Simulate a short task"
        Action = $demoActions.Task
    }
    @{
        Key = "4"
        Label = "Show PowerShell details"
        Action = $demoActions.Status
    }
)

Show-Info "Demo finished. You are back at your terminal."
