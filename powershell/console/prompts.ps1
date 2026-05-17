Set-StrictMode -Version 2.0

function Show-Choices {
    <#
    .SYNOPSIS
    Displays a numbered list of choices.

    .DESCRIPTION
    Prints each choice with a 1-based number. This is useful before calling
    Read-Choice, or when a script needs to show menu options without prompting.

    .PARAMETER Choices
    List of choice labels to display.

    .PARAMETER Color
    Console color used for the choice lines. Defaults to White.

    .EXAMPLE
    Show-Choices -Choices @("Install", "Update", "Exit")
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Choices,

        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    for ($i = 0; $i -lt $Choices.Count; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $Choices[$i]) -ForegroundColor $Color
    }
}

function Read-Choice {
    <#
    .SYNOPSIS
    Prompts the user to select from a fixed list of choices.

    .DESCRIPTION
    Displays a numbered list of choices and reads user input until a valid
    selection is provided. The user can enter either the number or the exact
    choice text. Returns the selected choice string.

    .PARAMETER Prompt
    Prompt shown before reading input.

    .PARAMETER Choices
    List of allowed choices.

    .PARAMETER Default
    Optional default choice used when the user presses Enter.

    .PARAMETER ShowMenu
    Displays the numbered menu before prompting. Enabled by default.

    .EXAMPLE
    $choice = Read-Choice -Prompt "Choose an action" -Choices @("Install", "Update", "Exit")

    .EXAMPLE
    $choice = Read-Choice -Prompt "Continue?" -Choices @("Yes", "No") -Default "Yes"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Choices,

        [string]$Default = "",

        [bool]$ShowMenu = $true
    )

    if (-not [string]::IsNullOrWhiteSpace($Default) -and $Choices -notcontains $Default) {
        throw "Default choice '$Default' does not exist in the provided choices."
    }

    if ($ShowMenu) {
        Show-Choices -Choices $Choices
    }

    while ($true) {
        $promptText = $Prompt
        if (-not [string]::IsNullOrWhiteSpace($Default)) {
            $promptText = "$Prompt [$Default]"
        }

        $raw = Read-Host $promptText

        if ([string]::IsNullOrWhiteSpace($raw) -and -not [string]::IsNullOrWhiteSpace($Default)) {
            return $Default
        }

        $inputText = $raw.Trim()
        $number = 0

        if ([int]::TryParse($inputText, [ref]$number)) {
            if ($number -ge 1 -and $number -le $Choices.Count) {
                return $Choices[$number - 1]
            }
        }

        foreach ($choice in $Choices) {
            if ($choice.Equals($inputText, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $choice
            }
        }

        Show-Warning "Invalid choice. Enter a number from 1 to $($Choices.Count), or type one of the listed values."
    }
}

function Read-Text {
    <#
    .SYNOPSIS
    Prompts the user for text input.

    .DESCRIPTION
    Reads text from the console with optional default and required validation.
    Returns the entered text, or the default value when provided and the user
    presses Enter.

    .PARAMETER Prompt
    Prompt shown before reading input.

    .PARAMETER Default
    Optional default value used when the user presses Enter.

    .PARAMETER Required
    Re-prompts until a non-empty value is entered.

    .EXAMPLE
    $name = Read-Text -Prompt "Project name" -Required

    .EXAMPLE
    $folder = Read-Text -Prompt "Output folder" -Default "dist"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Default = "",

        [switch]$Required
    )

    while ($true) {
        $promptText = $Prompt
        if (-not [string]::IsNullOrWhiteSpace($Default)) {
            $promptText = "$Prompt [$Default]"
        }

        $raw = Read-Host $promptText

        if ([string]::IsNullOrWhiteSpace($raw)) {
            if (-not [string]::IsNullOrWhiteSpace($Default)) {
                return $Default
            }

            if ($Required) {
                Show-Warning "A value is required."
                continue
            }
        }

        return $raw
    }
}

function Read-Confirm {
    <#
    .SYNOPSIS
    Prompts the user for a yes/no confirmation.

    .DESCRIPTION
    Reads a yes/no answer from the console and returns a Boolean value.

    .PARAMETER Prompt
    Confirmation prompt shown to the user.

    .PARAMETER Default
    Optional default answer. Valid values are Yes and No.

    .EXAMPLE
    if (Read-Confirm -Prompt "Continue?" -Default Yes) {
        Show-Success "Continuing"
    }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [ValidateSet("Yes", "No", "")]
        [string]$Default = ""
    )

    while ($true) {
        $suffix = "[y/n]"
        if ($Default -eq "Yes") {
            $suffix = "[Y/n]"
        } elseif ($Default -eq "No") {
            $suffix = "[y/N]"
        }

        $raw = Read-Host "$Prompt $suffix"

        if ([string]::IsNullOrWhiteSpace($raw) -and $Default -ne "") {
            return $Default -eq "Yes"
        }

        switch ($raw.Trim().ToLowerInvariant()) {
            "y" { return $true }
            "yes" { return $true }
            "n" { return $false }
            "no" { return $false }
            default { Show-Warning "Please answer yes or no." }
        }
    }
}
