Set-StrictMode -Version 2.0

function Get-UserEnvironmentVariable {
    <#
    .SYNOPSIS
    Gets a User environment variable.

    .PARAMETER Name
    Environment variable name.

    .OUTPUTS
    System.String. Environment variable value, or $null when missing.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return [Environment]::GetEnvironmentVariable($Name, "User")
}

function Get-RequiredEnvironmentVariable {
    <#
    .SYNOPSIS
    Gets a required environment variable.

    .DESCRIPTION
    Checks User scope first, then the current process. Throws when the variable
    is missing or empty.

    .PARAMETER Name
    Environment variable name.

    .OUTPUTS
    System.String. Environment variable value.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name, "User")
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    }

    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required environment variable: $Name."
    }

    return $value
}

function Set-UserEnvironmentVariable {
    <#
    .SYNOPSIS
    Persists a User environment variable and updates the current session.

    .PARAMETER Name
    Environment variable name.

    .PARAMETER Value
    Environment variable value.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path "Env:$Name" -Value $Value
}

function Normalize-PathEntry {
    <#
    .SYNOPSIS
    Normalizes a PATH entry for comparison.

    .DESCRIPTION
    Trims quotes, whitespace, trailing slashes, and normalizes path separators.
    This helper is intended for stable PATH comparisons, not for display.

    .PARAMETER Path
    PATH entry to normalize.

    .OUTPUTS
    System.String. Normalized PATH entry.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path.Trim().Trim('"').TrimEnd("\", "/").Replace("/", "\").ToLowerInvariant()
}

function Get-UserPathEntries {
    <#
    .SYNOPSIS
    Gets User PATH entries.

    .DESCRIPTION
    Reads the User PATH environment variable and returns non-empty entries in
    their current order.

    .OUTPUTS
    System.String[]. User PATH entries.
    #>
    $pathValue = Get-UserEnvironmentVariable -Name "Path"
    if ([string]::IsNullOrWhiteSpace($pathValue)) {
        return @()
    }

    return @($pathValue -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Set-UserPathEntries {
    <#
    .SYNOPSIS
    Replaces the User PATH with the provided entries.

    .DESCRIPTION
    Persists the User PATH environment variable and updates the current session.
    Empty entries are removed.

    .PARAMETER Entries
    Ordered PATH entries to persist.
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Entries
    )

    $cleanEntries = @($Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $pathValue = [string]::Join(";", $cleanEntries)
    Set-UserEnvironmentVariable -Name "Path" -Value $pathValue
}

function Test-UserPathEntry {
    <#
    .SYNOPSIS
    Checks whether a path exists in the User PATH.

    .PARAMETER Path
    PATH entry to search for.

    .OUTPUTS
    System.Boolean. True when the path is already in User PATH.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $target = Normalize-PathEntry -Path $Path
    foreach ($entry in Get-UserPathEntries) {
        if ((Normalize-PathEntry -Path $entry) -eq $target) {
            return $true
        }
    }

    return $false
}

function Add-UserPathEntry {
    <#
    .SYNOPSIS
    Adds a path to the User PATH if it is missing.

    .PARAMETER Path
    PATH entry to add.

    .PARAMETER Prepend
    Adds the entry at the beginning instead of the end.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Prepend
    )

    if (Test-UserPathEntry -Path $Path) {
        return $false
    }

    $entries = @(Get-UserPathEntries)
    if ($Prepend) {
        Set-UserPathEntries -Entries (@($Path) + $entries)
    } else {
        Set-UserPathEntries -Entries ($entries + @($Path))
    }

    return $true
}

function Remove-UserPathEntry {
    <#
    .SYNOPSIS
    Removes a path from the User PATH.

    .PARAMETER Path
    PATH entry to remove.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $target = Normalize-PathEntry -Path $Path
    $entries = @(Get-UserPathEntries)
    $remaining = @($entries | Where-Object { (Normalize-PathEntry -Path $_) -ne $target })

    if ($remaining.Count -eq $entries.Count) {
        return $false
    }

    Set-UserPathEntries -Entries $remaining
    return $true
}

function Update-UserPathEntry {
    <#
    .SYNOPSIS
    Replaces an existing User PATH entry.

    .DESCRIPTION
    Finds OldPath in User PATH and replaces it with NewPath while preserving
    entry order. If OldPath is missing, no change is made.

    .PARAMETER OldPath
    Existing PATH entry to replace.

    .PARAMETER NewPath
    Replacement PATH entry.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$OldPath,

        [Parameter(Mandatory)]
        [string]$NewPath
    )

    $target = Normalize-PathEntry -Path $OldPath
    $changed = $false
    $entries = @(
        Get-UserPathEntries | ForEach-Object {
            if ((Normalize-PathEntry -Path $_) -eq $target) {
                $changed = $true
                $NewPath
            } else {
                $_
            }
        }
    )

    if (-not $changed) {
        return $false
    }

    Set-UserPathEntries -Entries $entries
    return $true
}

function Upsert-UserPathEntry {
    <#
    .SYNOPSIS
    Updates or adds a User PATH entry.

    .DESCRIPTION
    If OldPath is provided and exists, it is replaced with Path. If Path already
    exists, no duplicate is added. Otherwise Path is added.

    .PARAMETER Path
    Desired PATH entry.

    .PARAMETER OldPath
    Optional old PATH entry to replace.

    .PARAMETER Prepend
    Adds a missing entry at the beginning instead of the end.

    .OUTPUTS
    System.String. One of Added, Updated, or Unchanged.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$OldPath = "",

        [switch]$Prepend
    )

    if (-not [string]::IsNullOrWhiteSpace($OldPath) -and (Update-UserPathEntry -OldPath $OldPath -NewPath $Path)) {
        return "Updated"
    }

    if (Add-UserPathEntry -Path $Path -Prepend:$Prepend) {
        return "Added"
    }

    return "Unchanged"
}
