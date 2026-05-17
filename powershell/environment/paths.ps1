Set-StrictMode -Version 2.0

function Resolve-PathFromDrive {
    <#
    .SYNOPSIS
    Builds a path from a drive and a relative path.

    .PARAMETER Drive
    Drive letter such as D:.

    .PARAMETER RelativePath
    Path relative to the drive root.

    .OUTPUTS
    System.String. Full path.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Drive,

        [Parameter(Mandatory)]
        [string]$RelativePath
    )

    $cleanRelativePath = $RelativePath.TrimStart([char[]]@("\", "/"))
    return Join-Path "$Drive\" $cleanRelativePath
}

function Convert-ToGitPath {
    <#
    .SYNOPSIS
    Converts a Windows path to a Git-friendly slash path.

    .PARAMETER Path
    Windows path to convert.

    .OUTPUTS
    System.String. Path with forward slashes.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path.Replace("\", "/")
}
