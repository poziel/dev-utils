Set-StrictMode -Version 2.0

function Get-DriveLetterByLabel {
    <#
    .SYNOPSIS
    Finds a drive letter by volume label.

    .DESCRIPTION
    Searches mounted Windows volumes for a label match. Matching is
    case-insensitive and ignores surrounding whitespace.

    .PARAMETER Label
    Volume label to search for.

    .OUTPUTS
    System.String. Drive letter such as D:, or $null when not found.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Label
    )

    $labelLower = $Label.Trim().ToLowerInvariant()

    $volume = Get-CimInstance -ClassName Win32_Volume -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DriveLetter -and
            $_.Label -and
            ($_.Label.Trim().ToLowerInvariant() -eq $labelLower)
        } |
        Select-Object -First 1

    if ($null -eq $volume) {
        return $null
    }

    return $volume.DriveLetter.TrimEnd("\")
}

function Normalize-DriveInput {
    <#
    .SYNOPSIS
    Normalizes user input into a valid drive letter.

    .DESCRIPTION
    Accepts values like D or D:, validates that the drive exists, and returns
    a normalized drive string like D:.

    .PARAMETER InputText
    User-entered drive text.

    .OUTPUTS
    System.String. Normalized drive letter, or $null when invalid.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$InputText
    )

    $letter = $InputText.Trim().TrimEnd(":").ToUpperInvariant()
    if ($letter -notmatch "^[A-Z]$") {
        return $null
    }

    $drive = "${letter}:"
    if (-not (Test-Path "$drive\")) {
        return $null
    }

    return $drive
}
