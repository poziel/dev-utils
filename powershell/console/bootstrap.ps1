Set-StrictMode -Version 2.0

$consoleFiles = @(
    "messages.ps1",
    "banner.ps1",
    "prompts.ps1"
)

if (Get-Variable -Name DevUtilsPowerShellCurrentImportBaseUrl -ErrorAction SilentlyContinue) {
    foreach ($file in $consoleFiles) {
        $consoleUrl = "$DevUtilsPowerShellCurrentImportBaseUrl/$file"
        $consoleContent = (Invoke-WebRequest -Uri $consoleUrl -UseBasicParsing -ErrorAction Stop).Content

        . ([scriptblock]::Create($consoleContent))
    }
    return
}

foreach ($file in $consoleFiles) {
    $consolePath = Join-Path $PSScriptRoot $file
    . $consolePath
}
