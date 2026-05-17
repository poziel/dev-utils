Set-StrictMode -Version 2.0

function Show-Break {
    <#
    .SYNOPSIS
    Writes one or more blank lines.

    .DESCRIPTION
    Adds vertical spacing to console output.

    .PARAMETER Count
    Number of blank lines to write. Defaults to 1.

    .EXAMPLE
    Show-Break

    .EXAMPLE
    Show-Break -Count 2
    #>
    param(
        [ValidateRange(1, 20)]
        [int]$Count = 1
    )

    for ($i = 0; $i -lt $Count; $i++) {
        Write-Host ""
    }
}

function Show-ConsoleMessage {
    <#
    .SYNOPSIS
    Writes a colored console message with an optional prefix.

    .DESCRIPTION
    Internal helper used by public console message functions.

    .PARAMETER Message
    Message text to display.

    .PARAMETER Prefix
    Optional prefix displayed before the message.

    .PARAMETER Color
    Console color used for the full line.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Prefix = "",

        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        Write-Host $Message -ForegroundColor $Color
        return
    }

    Write-Host "$Prefix $Message" -ForegroundColor $Color
}

function Get-ConsoleEmoji {
    <#
    .SYNOPSIS
    Gets an emoji character by semantic name.

    .DESCRIPTION
    Builds emoji characters from code points to avoid source-file encoding issues.

    .PARAMETER Name
    Emoji name. Supported values are Section, Info, Success, Warning, and Error.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    switch ($Name) {
        "Section" { return [char]::ConvertFromUtf32(0x1F537) }
        "Info" { return [char]::ConvertFromUtf32(0x2139) }
        "Success" { return [char]::ConvertFromUtf32(0x2705) }
        "Warning" { return [char]::ConvertFromUtf32(0x26A0) }
        "Error" { return [char]::ConvertFromUtf32(0x274C) }
        default { return "" }
    }
}

function Show-Section {
    <#
    .SYNOPSIS
    Writes a section heading.

    .DESCRIPTION
    Displays a lightweight section separator for grouping script output.

    .PARAMETER Message
    Section title to display.

    .PARAMETER UseEmoji
    Uses an emoji prefix instead of the default text prefix.

    .EXAMPLE
    Show-Section "Install"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$UseEmoji
    )

    Show-Break
    $prefix = if ($UseEmoji) { Get-ConsoleEmoji -Name "Section" } else { "==" }
    Show-ConsoleMessage -Prefix $prefix -Message $Message -Color Cyan
}

function Show-Info {
    <#
    .SYNOPSIS
    Writes an informational message.

    .PARAMETER Message
    Message text to display.

    .PARAMETER UseEmoji
    Uses an emoji prefix instead of the default text prefix.

    .EXAMPLE
    Show-Info "Checking environment"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$UseEmoji
    )

    $prefix = if ($UseEmoji) { Get-ConsoleEmoji -Name "Info" } else { "[INFO]" }
    Show-ConsoleMessage -Prefix $prefix -Message $Message -Color Gray
}

function Show-Success {
    <#
    .SYNOPSIS
    Writes a success message.

    .PARAMETER Message
    Message text to display.

    .PARAMETER UseEmoji
    Uses an emoji prefix instead of the default text prefix.

    .EXAMPLE
    Show-Success "Install complete"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$UseEmoji
    )

    $prefix = if ($UseEmoji) { Get-ConsoleEmoji -Name "Success" } else { "[OK]" }
    Show-ConsoleMessage -Prefix $prefix -Message $Message -Color Green
}

function Show-Warning {
    <#
    .SYNOPSIS
    Writes a warning message.

    .PARAMETER Message
    Message text to display.

    .PARAMETER UseEmoji
    Uses an emoji prefix instead of the default text prefix.

    .EXAMPLE
    Show-Warning "Optional setting was skipped"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$UseEmoji
    )

    $prefix = if ($UseEmoji) { Get-ConsoleEmoji -Name "Warning" } else { "[WARN]" }
    Show-ConsoleMessage -Prefix $prefix -Message $Message -Color Yellow
}

function Show-Error {
    <#
    .SYNOPSIS
    Writes an error message.

    .PARAMETER Message
    Message text to display.

    .PARAMETER UseEmoji
    Uses an emoji prefix instead of the default text prefix.

    .EXAMPLE
    Show-Error "Something failed"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [switch]$UseEmoji
    )

    $prefix = if ($UseEmoji) { Get-ConsoleEmoji -Name "Error" } else { "[ERROR]" }
    Show-ConsoleMessage -Prefix $prefix -Message $Message -Color Red
}
