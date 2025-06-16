# BPC.DBRefresh
## about_BPC.DBRefresh

# SHORT DESCRIPTION
BPC.DBRefresh is a PowerShell module for automating BusinessPlus test environment database refreshes. It provides tools to restore databases from production backups, configure security settings, and manage environment-specific configurations for K-12 school districts.

# LONG DESCRIPTION
The BPC.DBRefresh module automates the process of refreshing BusinessPlus test environments with production database backups. It handles the complete workflow including:

- Stopping BusinessPlus services across environment servers
- Restoring IFAS, SYSCAT, and ASPNET databases from backup files
- Reconfiguring database permissions and security settings
- Updating environment-specific configurations
- Disabling user accounts and workflows for test environments
- Restarting servers and sending completion notifications

This module is part of the BusinessPlus Community (BPC) namespace, which provides modular PowerShell tools for managing various aspects of BusinessPlus ERP/HR/PY systems.

# EXAMPLES

## Example 1: Basic Database Restore
```powershell
Invoke-BPERPDatabaseRestore -BPEnvironment 'TEST' -ifasFilePath 'C:\Backups\IFAS.bak' -syscatFilePath 'C:\Backups\SYSCAT.bak'
```

This example restores the IFAS and SYSCAT databases to the TEST environment.

## Example 2: Full Restore with ASPNET
```powershell
$params = @{
    BPEnvironment = 'DEV'
    ifasFilePath = 'C:\Backups\IFAS.bak'
    syscatFilePath = 'C:\Backups\SYSCAT.bak'
    aspnetFilePath = 'C:\Backups\ASPNET.bak'
    restoreDashboards = $true
}
Invoke-BPERPDatabaseRestore @params
```

This example performs a full restore including ASPNET database and dashboard files.

## Example 3: Testing Mode Restore
```powershell
Invoke-BPERPDatabaseRestore -BPEnvironment 'QA' -ifasFilePath 'C:\Backups\IFAS.bak' -syscatFilePath 'C:\Backups\SYSCAT.bak' -testingMode
```

This example restores databases with testing mode enabled, which creates additional test user accounts.

# NOTE
This module requires appropriate SQL Server permissions and access to BusinessPlus server environments. Configuration is managed through INI files that define environment-specific settings.

# TROUBLESHOOTING NOTE
For troubleshooting information, see the TROUBLESHOOTING.md file in the module's documentation folder.

# SEE ALSO
- Invoke-BPERPDatabaseRestore
- Set-BPERPConfiguration
- Get-BPERPDatabaseSettings
- https://github.com/businessplus-community/BPC.DBRefresh

# KEYWORDS
- BPC
- BusinessPlus
- Database
- Restore
- K12
- Education
- ERP
- Automation