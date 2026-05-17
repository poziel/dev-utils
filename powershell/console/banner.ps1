Set-StrictMode -Version 2.0

function Show-Banner {
    <#
    .SYNOPSIS
    Displays a large script title banner.

    .DESCRIPTION
    Writes a top separator, a centered title line, an optional centered subtitle,
    and a bottom separator. Useful at the beginning of setup scripts and CLI tools.

    .PARAMETER Title
    Main title displayed in the middle of the banner.

    .PARAMETER Subtitle
    Optional subtitle displayed below the title.

    .PARAMETER Width
    Total banner width. Defaults to 60.

    .PARAMETER Character
    Character used for the top and bottom separator lines. Defaults to "=".

    .PARAMETER Color
    Console color used for the banner. Defaults to Cyan.

    .EXAMPLE
    Show-Banner "Apps Shortcut Sync Tool"

    .EXAMPLE
    Show-Banner "Drive Setup" -Subtitle "Environment variables" -Width 72 -Color Magenta
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [string]$Subtitle = "",

        [ValidateRange(20, 200)]
        [int]$Width = 60,

        [ValidateLength(1, 1)]
        [string]$Character = "=",

        [ConsoleColor]$Color = [ConsoleColor]::Cyan
    )

    $lines = @($Title)
    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        $lines += $Subtitle
    }

    $longestLine = ($lines | Measure-Object -Property Length -Maximum).Maximum
    $effectiveWidth = [Math]::Max($Width, $longestLine + 8)
    $separator = $Character * $effectiveWidth

    Show-Break
    Write-Host $separator -ForegroundColor $Color

    foreach ($line in $lines) {
        $padding = [Math]::Max(0, $effectiveWidth - $line.Length)
        $leftPadding = [Math]::Floor($padding / 2)
        $rightPadding = $padding - $leftPadding
        Write-Host (" " * $leftPadding + $line + " " * $rightPadding) -ForegroundColor $Color
    }

    Write-Host $separator -ForegroundColor $Color
    Show-Break
}
