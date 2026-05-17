Set-StrictMode -Version 2.0

$environmentFiles = @(
    "variables.ps1",
    "drives.ps1",
    "paths.ps1"
)

if (Get-Variable -Name DevUtilsPowerShellCurrentImportBaseUrl -ErrorAction SilentlyContinue) {
    foreach ($file in $environmentFiles) {
        $environmentUrl = "$DevUtilsPowerShellCurrentImportBaseUrl/$file"
        $environmentContent = (Invoke-WebRequest -Uri $environmentUrl -UseBasicParsing -ErrorAction Stop).Content

        . ([scriptblock]::Create($environmentContent))
    }
    return
}

foreach ($file in $environmentFiles) {
    $environmentPath = Join-Path $PSScriptRoot $file
    . $environmentPath
}
