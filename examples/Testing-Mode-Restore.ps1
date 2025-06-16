<#
.SYNOPSIS
    Example of restoring with testing mode enabled

.DESCRIPTION
    This example demonstrates how to restore a BusinessPlus test environment
    with testing mode enabled, which preserves additional test accounts.

.NOTES
    Testing mode is useful when you need multiple active accounts for testing
    different user roles and permissions.
#>

# Import the module
Import-Module BPC.DBRefresh -ErrorAction Stop

# Restore with testing mode enabled
$restoreParams = @{
    BPEnvironment  = 'QA'
    ifasFilePath   = '\\backup-server\backups\IFAS_PROD_20240115.bak'
    syscatFilePath = '\\backup-server\backups\SYSCAT_PROD_20240115.bak'
    aspnetFilePath = '\\backup-server\backups\ASPNET_PROD_20240115.bak'
    testingMode    = $true  # Enable testing mode to preserve test accounts
}

Invoke-BPERPDatabaseRestore @restoreParams

Write-Host 'Restore completed with testing mode enabled.' -ForegroundColor Green
Write-Host 'Additional test accounts have been preserved for QA testing.' -ForegroundColor Yellow
