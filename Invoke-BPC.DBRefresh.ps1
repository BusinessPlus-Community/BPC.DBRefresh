<#
.SYNOPSIS
    Wrapper script for backward compatibility with the original BPC.DBRefresh.ps1

.DESCRIPTION
    This script provides backward compatibility for users who are used to calling
    BPC.DBRefresh.ps1 directly. It imports the new module and calls the
    appropriate function with the provided parameters.

.NOTES
    This is a compatibility wrapper. For new implementations, please use:
    Import-Module BPC.DBRefresh
    Invoke-BPERPDatabaseRestore [parameters]

.LINK
    https://github.com/businessplus-community/BPC.DBRefresh
#>

[CmdletBinding()]
Param (
    [String]
    [Parameter(Position = 0, Mandatory = $true)]
    $BPEnvironment,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ -IsValid})]
    [Parameter(Position = 1)]
    [String]
    $aspnetFilePath,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ -IsValid})]
    [Parameter(Position = 2, Mandatory = $true)]
    [String]
    $ifasFilePath,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ -IsValid})]
    [Parameter(Position = 3, Mandatory = $true)]
    [String]
    $syscatFilePath,

    [Parameter(Position = 4, Mandatory = $false)]
    [switch]
    $testingMode = $false,

    [Parameter(Position = 5, Mandatory = $false)]
    [switch]
    $restoreDashboards = $false
)

# Import the module
$modulePath = Join-Path $PSScriptRoot "src\BPC.DBRefresh"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "BPC.DBRefresh module not found at: $modulePath"
    Write-Error "Please ensure the module is properly installed."
    exit 1
}

# Set the config path to use the new location
$configPath = Join-Path $PSScriptRoot "config\BPC.DBRefresh.ini"

# Build parameters for the module function
$moduleParams = @{
    BPEnvironment = $BPEnvironment
    IfasFilePath = $ifasFilePath
    SyscatFilePath = $syscatFilePath
}

if ($PSBoundParameters.ContainsKey('aspnetFilePath')) {
    $moduleParams.AspnetFilePath = $aspnetFilePath
}

if ($testingMode) {
    $moduleParams.TestingMode = $true
}

if ($restoreDashboards) {
    $moduleParams.RestoreDashboards = $true
}

# Add config path
$moduleParams.ConfigPath = $configPath

# Call the module function
try {
    Invoke-BPERPDatabaseRestore @moduleParams
}
catch {
    Write-Error "Error during restore operation: $_"
    exit 1
}
