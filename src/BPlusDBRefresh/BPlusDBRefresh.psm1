#Requires -Version 5.1
<#
.SYNOPSIS
    BPlusDBRefresh module - Automates BusinessPlus test environment database refresh.

.DESCRIPTION
    This module provides functions to automate the process of refreshing BusinessPlus
    test environment databases, including service management, database restoration,
    permission configuration, and notification.

.NOTES
    Module: BPlusDBRefresh
    Version: 2.0.0
    Author: Zachary V. Birge
    Refactored following PoshCode PowerShell Practice and Style Guide
#>

# Get the module root path
$script:ModuleRoot = $PSScriptRoot

# Get the resources path
$script:ResourcesPath = Join-Path -Path $script:ModuleRoot -ChildPath 'Resources'

# Dot-source all private functions
$privateFunctions = Get-ChildItem -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
    } catch {
        Write-Error -Message "Failed to import private function $($function.BaseName): $_"
    }
}

# Dot-source all public functions
$publicFunctions = Get-ChildItem -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($function in $publicFunctions) {
    try {
        . $function.FullName
    } catch {
        Write-Error -Message "Failed to import public function $($function.BaseName): $_"
    }
}

# Export public functions (also specified in manifest for performance)
Export-ModuleMember -Function $publicFunctions.BaseName -ErrorAction SilentlyContinue
