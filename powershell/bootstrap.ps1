param(
    [string[]]$Imports = @()
)

Set-StrictMode -Version 2.0

$DevUtilsPowerShellBaseUrl = "https://raw.githubusercontent.com/poziel/dev-utils/refs/heads/main/powershell"

function Test-DevUtilsImportName {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return $Name -match "^[A-Za-z][A-Za-z0-9_-]*$"
}

foreach ($import in $Imports) {
    if ([string]::IsNullOrWhiteSpace($import)) {
        continue
    }

    $importName = $import.Trim().ToLowerInvariant()
    if (-not (Test-DevUtilsImportName -Name $importName)) {
        Write-Warning "Skipping invalid dev-utils PowerShell import name: '$import'."
        continue
    }

    $pluginBootstrapUrl = "$DevUtilsPowerShellBaseUrl/$importName/bootstrap.ps1"

    try {
        $pluginBootstrapContent = (Invoke-WebRequest -Uri $pluginBootstrapUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        Write-Warning "Skipping dev-utils PowerShell import '$importName'. Could not load: $pluginBootstrapUrl"
        continue
    }

    $previousImportBaseUrl = Get-Variable -Name DevUtilsPowerShellCurrentImportBaseUrl -ValueOnly -ErrorAction SilentlyContinue
    $DevUtilsPowerShellCurrentImportBaseUrl = "$DevUtilsPowerShellBaseUrl/$importName"

    try {
        # Dot-source at bootstrap top level so imported functions remain available to the caller.
        . ([scriptblock]::Create($pluginBootstrapContent))
    }
    finally {
        if ($null -ne $previousImportBaseUrl) {
            $DevUtilsPowerShellCurrentImportBaseUrl = $previousImportBaseUrl
        } else {
            Remove-Variable -Name DevUtilsPowerShellCurrentImportBaseUrl -ErrorAction SilentlyContinue
        }
    }
}
