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
