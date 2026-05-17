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

function Test-IsAdmin {
    <#
    .SYNOPSIS
    Checks whether the current PowerShell session is elevated.

    .OUTPUTS
    System.Boolean. True when the current process has Administrator privileges.
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-EnvironmentScopeAccess {
    <#
    .SYNOPSIS
    Throws when the current process cannot write to the requested environment scope.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("User", "Machine")]
        [string]$Scope
    )

    if ($Scope -eq "Machine" -and -not (Test-IsAdmin)) {
        throw "Administrator rights are required to modify the Machine PATH."
    }
}

function Get-PathEntries {
    <#
    .SYNOPSIS
    Gets PATH entries for the requested environment scope.

    .DESCRIPTION
    Reads the PATH environment variable and returns non-empty entries in their
    current order.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .OUTPUTS
    System.String[]. PATH entries.
    #>
    param(
        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    $pathValue = [Environment]::GetEnvironmentVariable("Path", $Scope)
    if ([string]::IsNullOrWhiteSpace($pathValue)) {
        return @()
    }

    return @($pathValue -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Set-PathEntries {
    <#
    .SYNOPSIS
    Replaces PATH entries for the requested environment scope.

    .DESCRIPTION
    Persists the PATH environment variable for the requested scope. Empty
    entries are removed. The current process PATH is updated only for User
    scope because Machine PATH changes should be picked up by new processes.

    .PARAMETER Entries
    Ordered PATH entries to persist.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$Entries,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    Assert-EnvironmentScopeAccess -Scope $Scope

    $cleanEntries = @($Entries | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $pathValue = [string]::Join(";", $cleanEntries)
    [Environment]::SetEnvironmentVariable("Path", $pathValue, $Scope)

    if ($Scope -eq "User") {
        Set-Item -Path "Env:Path" -Value $pathValue
    }
}

function Test-PathEntry {
    <#
    .SYNOPSIS
    Checks whether a path exists in PATH for the requested environment scope.

    .PARAMETER Path
    PATH entry to search for.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .OUTPUTS
    System.Boolean. True when the path is already in PATH.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    $target = Normalize-PathEntry -Path $Path
    foreach ($entry in Get-PathEntries -Scope $Scope) {
        if ((Normalize-PathEntry -Path $entry) -eq $target) {
            return $true
        }
    }

    return $false
}

function Add-PathEntry {
    <#
    .SYNOPSIS
    Adds a path to PATH for the requested environment scope if it is missing.

    .PARAMETER Path
    PATH entry to add.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .PARAMETER Prepend
    Adds the entry at the beginning instead of the end.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",

        [switch]$Prepend
    )

    if (Test-PathEntry -Path $Path -Scope $Scope) {
        return $false
    }

    $entries = @(Get-PathEntries -Scope $Scope)
    if ($Prepend) {
        Set-PathEntries -Entries (@($Path) + $entries) -Scope $Scope
    } else {
        Set-PathEntries -Entries ($entries + @($Path)) -Scope $Scope
    }

    return $true
}

function Remove-PathEntry {
    <#
    .SYNOPSIS
    Removes a path from PATH for the requested environment scope.

    .PARAMETER Path
    PATH entry to remove.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    $target = Normalize-PathEntry -Path $Path
    $entries = @(Get-PathEntries -Scope $Scope)
    $remaining = @($entries | Where-Object { (Normalize-PathEntry -Path $_) -ne $target })

    if ($remaining.Count -eq $entries.Count) {
        return $false
    }

    Set-PathEntries -Entries $remaining -Scope $Scope
    return $true
}

function Update-PathEntry {
    <#
    .SYNOPSIS
    Replaces an existing PATH entry for the requested environment scope.

    .DESCRIPTION
    Finds OldPath in PATH and replaces it with NewPath while preserving
    entry order. If OldPath is missing, no change is made.

    .PARAMETER OldPath
    Existing PATH entry to replace.

    .PARAMETER NewPath
    Replacement PATH entry.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .OUTPUTS
    System.Boolean. True when the PATH was changed.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$OldPath,

        [Parameter(Mandatory)]
        [string]$NewPath,

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User"
    )

    $target = Normalize-PathEntry -Path $OldPath
    $changed = $false
    $entries = @(
        Get-PathEntries -Scope $Scope | ForEach-Object {
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

    Set-PathEntries -Entries $entries -Scope $Scope
    return $true
}

function Upsert-PathEntry {
    <#
    .SYNOPSIS
    Updates or adds a PATH entry for the requested environment scope.

    .DESCRIPTION
    If OldPath is provided and exists, it is replaced with Path. If Path already
    exists, no duplicate is added. Otherwise Path is added.

    .PARAMETER Path
    Desired PATH entry.

    .PARAMETER OldPath
    Optional old PATH entry to replace.

    .PARAMETER Scope
    Environment scope. Valid values are User and Machine. Defaults to User.

    .PARAMETER Prepend
    Adds a missing entry at the beginning instead of the end.

    .OUTPUTS
    System.String. One of Added, Updated, or Unchanged.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$OldPath = "",

        [ValidateSet("User", "Machine")]
        [string]$Scope = "User",

        [switch]$Prepend
    )

    if (-not [string]::IsNullOrWhiteSpace($OldPath) -and (Update-PathEntry -OldPath $OldPath -NewPath $Path -Scope $Scope)) {
        return "Updated"
    }

    if (Add-PathEntry -Path $Path -Scope $Scope -Prepend:$Prepend) {
        return "Added"
    }

    return "Unchanged"
}

function Get-UserPathEntries { <# .SYNOPSIS Gets User PATH entries. #> Get-PathEntries -Scope User }
function Set-UserPathEntries { <# .SYNOPSIS Replaces User PATH entries. #> param([Parameter(Mandatory)][string[]]$Entries) Set-PathEntries -Entries $Entries -Scope User }
function Test-UserPathEntry { <# .SYNOPSIS Checks whether a path exists in User PATH. #> param([Parameter(Mandatory)][string]$Path) Test-PathEntry -Path $Path -Scope User }
function Add-UserPathEntry { <# .SYNOPSIS Adds a path to User PATH if missing. #> param([Parameter(Mandatory)][string]$Path,[switch]$Prepend) Add-PathEntry -Path $Path -Scope User -Prepend:$Prepend }
function Remove-UserPathEntry { <# .SYNOPSIS Removes a path from User PATH. #> param([Parameter(Mandatory)][string]$Path) Remove-PathEntry -Path $Path -Scope User }
function Update-UserPathEntry { <# .SYNOPSIS Replaces an existing User PATH entry. #> param([Parameter(Mandatory)][string]$OldPath,[Parameter(Mandatory)][string]$NewPath) Update-PathEntry -OldPath $OldPath -NewPath $NewPath -Scope User }
function Upsert-UserPathEntry { <# .SYNOPSIS Updates or adds a User PATH entry. #> param([Parameter(Mandatory)][string]$Path,[string]$OldPath = "",[switch]$Prepend) Upsert-PathEntry -Path $Path -OldPath $OldPath -Scope User -Prepend:$Prepend }
