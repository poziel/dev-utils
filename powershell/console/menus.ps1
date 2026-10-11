Set-StrictMode -Version 2.0

function Read-MenuKey {
    <#
    .SYNOPSIS
    Internal helper that reads a menu key without requiring Enter.

    .PARAMETER ReadLine
    Uses Read-Host for hosts that do not support single-key input.
    #>
    param(
        [switch]$ReadLine
    )

    if ($ReadLine) {
        return (Read-Host "Choose an option").Trim()
    }

    Write-Host "Choose an option: " -NoNewline
    try {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        throw "This host cannot read single keys. Call Show-Menu with -ReadLine to enter a choice followed by Enter. $($_.Exception.Message)"
    }

    Write-Host $key.Character
    return [string]$key.Character
}

function Show-Menu {
    <#
    .SYNOPSIS
    Displays a script banner and runs actions selected by a single keypress.

    .DESCRIPTION
    Displays the title, optional description, and options in the supplied order.
    Each option is a hashtable with Key, Label, and Action entries. Keys are
    single letters or digits, are case-insensitive, and do not need to be consecutive.
    Q is reserved for quitting when AllowQuit is enabled. Invalid input redraws
    the menu with one red hint listing the available keys above the prompt.
    Clears the screen before each menu and action. After an action completes,
    waits for Enter before returning to the menu. Q returns to the calling
    script without closing PowerShell. Action output is displayed in the host;
    terminating errors propagate to the caller.

    .PARAMETER Title
    Script name displayed using Show-Banner.

    .PARAMETER Description
    Optional description displayed below the banner.

    .PARAMETER Options
    Ordered list of hashtables containing Key, Label, and an Action scriptblock.
    Actions run in a child scope and can read variables and call functions from
    the calling script.

    .PARAMETER ReadLine
    Requires Enter after a choice. Use in hosts without single-key input support.

    .PARAMETER AllowQuit
    Adds the built-in Q option. Defaults to true. Set to false to disable it.

    .EXAMPLE
    Show-Menu -Title "Setup Tool" -Description "Install and maintain your tools." -Options @(
        @{ Key = "1"; Label = "Install"; Action = { Install-Tools } }
        @{ Key = "2"; Label = "Update"; Action = { Update-Tools } }
        @{ Key = "4"; Label = "Check status"; Action = { Get-ToolStatus } }
    )
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [string]$Description = "",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Options,

        [switch]$ReadLine,

        [bool]$AllowQuit = $true
    )

    $actions = @{}
    foreach ($option in $Options) {
        if ($null -eq $option -or -not $option.Contains("Key") -or
            -not $option.Contains("Label") -or -not $option.Contains("Action")) {
            throw "Each menu option must contain Key, Label, and Action entries."
        }

        $optionKey = [string]$option["Key"]
        if ($optionKey -notmatch "^[A-Za-z0-9]$") {
            throw "Menu key '$optionKey' must be a single letter or digit."
        }
        if ($AllowQuit -and $optionKey -eq "Q") {
            throw "Menu key 'Q' is reserved for quitting."
        }
        if ($actions.ContainsKey($optionKey)) {
            throw "Menu key '$optionKey' is duplicated."
        }
        if ([string]::IsNullOrWhiteSpace([string]$option["Label"])) {
            throw "Menu option '$optionKey' must have a non-empty label."
        }
        if ($option["Action"] -isnot [scriptblock]) {
            throw "Menu option '$optionKey' must have an Action scriptblock."
        }

        $actions[$optionKey] = $option["Action"]
    }

    $menuKeys = @($Options | ForEach-Object { [string]$_["Key"] })
    if ($AllowQuit) {
        $menuKeys += "Q"
    }
    $keyList = if ($menuKeys.Count -eq 1) {
        $menuKeys[0]
    } elseif ($menuKeys.Count -eq 2) {
        $menuKeys -join " or "
    } else {
        ($menuKeys[0..($menuKeys.Count - 2)] -join ", ") + ", or " + $menuKeys[-1]
    }
    $choiceHint = if ($AllowQuit) { "Press $keyList to quit." } else { "Press $keyList." }
    $invalidChoice = $false

    while ($true) {
        Clear-Host
        Show-Banner -Title $Title
        if (-not [string]::IsNullOrWhiteSpace($Description)) {
            Write-Host $Description -ForegroundColor Gray
            Write-Host ""
        }

        foreach ($option in $Options) {
            Write-Host ("  {0}) {1}" -f $option["Key"], $option["Label"]) -ForegroundColor White
        }
        if ($AllowQuit) {
            Write-Host "  Q) Quit" -ForegroundColor White
        }
        Write-Host ""
        if ($invalidChoice) {
            Write-Host $choiceHint -ForegroundColor Red
        } else {
            Write-Host ""
        }

        $selectedKey = Read-MenuKey -ReadLine:$ReadLine
        if ($AllowQuit -and $selectedKey -eq "Q") {
            return
        }
        if (-not $actions.ContainsKey($selectedKey)) {
            $invalidChoice = $true
            continue
        }

        $invalidChoice = $false
        Clear-Host
        & $actions[$selectedKey] | Out-Host
        Write-Host ""
        Wait-Continue -Message "Press Enter to return to the menu"
    }
}
