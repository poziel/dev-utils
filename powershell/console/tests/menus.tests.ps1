# Run with powershell.exe or pwsh -NoProfile -File .\menus.tests.ps1.
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\bootstrap.ps1")

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

# Replace only the input/output boundary so tests never wait for a terminal.
function Write-Host {
    param($Object, $ForegroundColor, [switch]$NoNewline)
    $menuTestState.Display.Add([string]$Object)
    $menuTestState.Writes.Add(@{ Text = [string]$Object; Color = $ForegroundColor })
    if ($menuTestState.Frames.Count -gt 0) {
        $menuTestState.Frames[-1].Add([string]$Object)
    }
}
function Read-Host {
    param($Prompt)
    $menuTestState.Events.Add("Read:$Prompt")
    if ($menuTestState.Frames.Count -gt 0) { $menuTestState.Frames[-1].Add("<PROMPT>") }
    if ($menuTestState.Keys.Count -eq 0) { throw "Unexpected extra input request." }
    return $menuTestState.Keys.Dequeue()
}
function Clear-Host {
    $menuTestState.Events.Add("Clear")
    $menuTestState.Frames.Add((New-Object 'System.Collections.Generic.List[string]'))
}

$script:events = New-Object 'System.Collections.Generic.List[string]'
$script:display = New-Object 'System.Collections.Generic.List[string]'
$script:keys = New-Object 'System.Collections.Generic.Queue[string]'
$script:ran = New-Object 'System.Collections.Generic.List[string]'
$menuTestState = @{ Display = $script:display; Events = $script:events; Keys = $script:keys }
$menuTestState.Writes = New-Object 'System.Collections.Generic.List[object]'
$menuTestState.Frames = New-Object 'System.Collections.Generic.List[object]'
$callerValue = "visible"
$options = @(
    @{ Key = "1"; Label = "First"; Action = { $script:ran.Add("1:$callerValue"); $script:events.Add("Action:1") } }
    @{ Key = "2"; Label = "Second"; Action = { $script:ran.Add("2"); $script:events.Add("Action:2") } }
    @{ Key = "4"; Label = "Fourth"; Action = { $script:ran.Add("4"); $script:events.Add("Action:4") } }
    @{ Key = "A"; Label = "Letter"; Action = { $script:ran.Add("A"); $script:events.Add("Action:A") } }
)
foreach ($key in @("", "3", "12", "1", "", "2", "", "4", "", "a", "", " q ")) { $script:keys.Enqueue($key) }
Show-Menu -Title "Test menu" -Description "Test description" -Options $options -ReadLine
Assert-True (($script:ran -join ",") -eq "1:visible,2,4,A") "Actions or caller variable access failed."
Assert-True ($script:keys.Count -eq 0) "Quit did not consume the expected input."
Assert-True (@($script:display | Where-Object { $_ -eq "Press 1, 2, 4, A, or Q to quit." }).Count -eq 3) "Invalid input must list actual keys."
Assert-True (@($script:display | Where-Object { $_ -eq "  Q) Quit" }).Count -eq 8) "Menu was not redrawn after invalid input and actions."
Assert-True ($script:display.Contains("Test description")) "Description missing."
$firstIndex = $script:display.IndexOf("  1) First")
Assert-True ($firstIndex -ge 0 -and $script:display[$firstIndex + 2] -eq "  4) Fourth") "Option order changed."
Assert-True ($script:events[0] -eq "Clear") "The initial menu must clear the screen."
foreach ($key in @("1", "2", "4", "A")) {
    $actionIndex = $script:events.IndexOf("Action:$key")
    Assert-True ($script:events[$actionIndex - 1] -eq "Clear") "Clear must precede action $key."
    Assert-True ($script:events[$actionIndex + 1] -eq "Read:") "Action $key must wait for Enter without a Read-Host prompt."
    Assert-True ($script:events[$actionIndex + 2] -eq "Clear") "Returning from action $key must clear the screen."
}
Assert-True (@($script:events | Where-Object { $_ -eq "Clear" }).Count -eq 12) "Every invalid choice must redraw the menu."
$firstFrame = $menuTestState.Frames[0]
Assert-True (($firstFrame.GetRange($firstFrame.Count - 4, 4) -join "|") -eq "  Q) Quit|||<PROMPT>") "Reserve two blank lines above the prompt."
foreach ($frame in $menuTestState.Frames) {
    $hints = @($frame | Where-Object { $_ -eq "Press 1, 2, 4, A, or Q to quit." })
    Assert-True ($hints.Count -le 1) "Error hints must not accumulate."
    if ($hints.Count -eq 1) {
        Assert-True ($frame[-2] -eq $hints[0] -and $frame[-1] -eq "<PROMPT>") "Error hint must be immediately above the prompt."
    }
}
foreach ($write in @($menuTestState.Writes | Where-Object { $_.Text -eq "Press 1, 2, 4, A, or Q to quit." })) {
    Assert-True ($write.Color -eq "Red") "Menu hints must be red."
}
Assert-True ($script:display.Contains("Press Enter to return to the menu")) "Pause message missing or has unwanted punctuation."

$script:keys.Enqueue("")
$pauseOutput = @(Wait-Continue)
Assert-True ($pauseOutput.Count -eq 0) "Wait-Continue must not return input as output."
Assert-True ($script:events[$script:events.Count - 1] -eq "Read:" -and $script:display[-1] -eq "Press Enter to continue") "Standalone pause must render its own message without a colon."

# Letter keys and short lists use natural wording in the supplied order.
foreach ($case in @(
    @{ Keys = @("1", "2", "H", "U"); Hint = "Press 1, 2, H, U, or Q to quit." }
    @{ Keys = @("H"); Hint = "Press H or Q to quit." }
)) {
    $hintOptions = @($case.Keys | ForEach-Object { @{ Key = $_; Label = $_; Action = {} } })
    $script:keys.Enqueue("x")
    $script:keys.Enqueue("q")
    Show-Menu -Title "Key hints" -Options $hintOptions -ReadLine
    Assert-True ($script:display.Contains($case.Hint)) "Natural key list missing: $($case.Hint)"
}

# With quit disabled, Q must neither appear nor exit; a valid action still runs.
foreach ($case in @(
    @{ Keys = @("1"); Hint = "Press 1." }
    @{ Keys = @("1", "H"); Hint = "Press 1 or H." }
    @{ Keys = @("1", "H", "U"); Hint = "Press 1, H, or U." }
)) {
    $startDisplay = $script:display.Count
    $hintOptions = @($case.Keys | ForEach-Object { @{ Key = $_; Label = $_; Action = { throw "Test action reached" } } })
    $script:keys.Enqueue("q")
    $script:keys.Enqueue("1")
    $caught = $false
    try { Show-Menu -Title "No quit" -Options $hintOptions -AllowQuit $false -ReadLine }
    catch { $caught = $_.Exception.Message -eq "Test action reached" }
    Assert-True $caught "Disabling quit must reject Q and allow the selected action."
    $newDisplay = $script:display.GetRange($startDisplay, $script:display.Count - $startDisplay)
    Assert-True (-not $newDisplay.Contains("  Q) Quit")) "Disabled quit must not be displayed."
    Assert-True ($newDisplay.Contains($case.Hint)) "Disabled quit must not appear in the hint."
}
$script:keys.Enqueue("q")
$caught = $false
try {
    Show-Menu -Title "Custom Q" -AllowQuit $false -Options @(@{ Key = "Q"; Label = "Custom action"; Action = { throw "Custom Q reached" } }) -ReadLine
}
catch { $caught = $_.Exception.Message -eq "Custom Q reached" }
Assert-True $caught "Q may be assigned an action when built-in quit is disabled."

foreach ($badOptions in @(
    @{ Options = @(@{ Key = "q"; Label = "Reserved"; Action = {} }); Error = "*reserved*" }
    @{ Options = @(@{ Key = "12"; Label = "Long"; Action = {} }); Error = "*single letter or digit*" }
    @{ Options = @(@{ Key = "1"; Label = " "; Action = {} }); Error = "*non-empty label*" }
    @{ Options = @(@{ Key = "1"; Label = "Bad"; Action = "text" }); Error = "*scriptblock*" }
    @{ Options = @(@{ Key = "1"; Label = "Missing" }); Error = "*must contain*" }
    @{ Options = @(@{ Key = "a"; Label = "One"; Action = {} }, @{ Key = "A"; Label = "Two"; Action = {} }); Error = "*duplicated*" }
)) {
    $caught = $false
    try { Show-Menu -Title "Invalid" -Options $badOptions.Options -ReadLine }
    catch { $caught = $_.Exception.Message -like $badOptions.Error }
    Assert-True $caught "Expected validation error: $($badOptions.Error)"
}

$script:keys.Enqueue("1")
$caught = $false
try {
    Show-Menu -Title "Failure" -Options @(@{ Key = "1"; Label = "Fail"; Action = { throw "Action failed" } }) -ReadLine
}
catch { $caught = $_.Exception.Message -eq "Action failed" }
Assert-True $caught "Action errors must reach the caller."

# Direct arguments use PowerShell binding and must never clear or prompt.
$demoPath = Join-Path $PSScriptRoot "..\examples\menu.ps1"
$eventCount = $script:events.Count
& $demoPath -Action Task -TaskName "Custom task"
Assert-True ($script:display.Contains("== Custom task")) "Custom task argument was not forwarded."
& $demoPath -Action Task
Assert-True ($script:display.Contains("== Sample task")) "Default task name missing."
& $demoPath -Action Hello
& $demoPath -Action Status
Assert-True ($script:display.Contains("== Your session")) "Direct status action did not run."
Assert-True ($script:events.Count -eq $eventCount) "Direct execution must not clear or prompt."

foreach ($case in @(
    @{ Arguments = @{ Unknown = "value" }; Error = "NamedParameterNotFound*" }
    @{ Arguments = @{ Action = "Unknown" }; Error = "ParameterArgumentValidationError*" }
    @{ Arguments = @{ Action = "Task"; TaskName = "" }; Error = "ParameterArgumentValidationError*" }
)) {
    $caught = $false
    try { $demoArguments = $case.Arguments; & $demoPath @demoArguments }
    catch { $caught = $_.FullyQualifiedErrorId -like $case.Error }
    Assert-True $caught "Expected argument binding error: $($case.Error)"
}
$caught = $false
try { & $demoPath "unexpected" }
catch { $caught = $_.FullyQualifiedErrorId -like "PositionalParameterNotFound*" }
Assert-True $caught "Unexpected positional arguments must be rejected."
Assert-True ($script:events.Count -eq $eventCount) "Invalid arguments must fail before interactive work."

# Supplying only a task name still opens the menu and uses that value in option 2.
foreach ($key in @("2", "", "q")) { $script:keys.Enqueue($key) }
& $demoPath -TaskName "Interactive task" -ReadLine
Assert-True ($script:display.Contains("== Interactive task")) "Menu action did not receive the supplied task name."
Assert-True ($script:keys.Count -eq 0) "Interactive demo did not pause and quit correctly."

# Exercise the web bootstrap with local responses, without publishing or network access.
$script:powershellRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:requested = New-Object 'System.Collections.Generic.List[string]'
function Invoke-WebRequest {
    param($Uri, [switch]$UseBasicParsing, $ErrorAction)
    $prefix = "https://raw.githubusercontent.com/poziel/dev-utils/refs/heads/main/powershell/"
    Assert-True ($Uri.StartsWith($prefix)) "Unexpected bootstrap URL: $Uri"
    $relative = $Uri.Substring($prefix.Length)
    $script:requested.Add($relative)
    return @{ Content = Get-Content -LiteralPath (Join-Path $script:powershellRoot $relative) -Raw }
}
Remove-Item Function:Show-Menu
. (Join-Path $script:powershellRoot "bootstrap.ps1") -Imports Console
Assert-True ($null -ne (Get-Command Show-Menu -ErrorAction SilentlyContinue)) "Web bootstrap did not expose Show-Menu."
Assert-True ($script:requested.Contains("console/menus.ps1")) "Web bootstrap did not load menus.ps1."
$script:keys.Enqueue("Q")
Show-Menu -Title "Imported menu" -Options $options -ReadLine

Microsoft.PowerShell.Utility\Write-Host "Menu checks passed on PowerShell $($PSVersionTable.PSVersion)."
