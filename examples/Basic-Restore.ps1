<#
.SYNOPSIS
    Basic example of restoring a BusinessPlus test environment

.DESCRIPTION
    This example shows the simplest way to restore a BusinessPlus test environment
    with just the required parameters.

.NOTES
    Ensure you have:
    - Updated the configuration file with your environment settings
    - Access to the backup files
    - Appropriate permissions on the SQL Server and target servers
#>

# Import the module (if not already imported)
Import-Module BPC.DBRefresh -ErrorAction Stop

# Basic restore with required parameters only
Invoke-BPERPDatabaseRestore -BPEnvironment 'TEST' `
    -ifasFilePath '\\backup-server\backups\IFAS_PROD_20240115.bak' `
    -syscatFilePath '\\backup-server\backups\SYSCAT_PROD_20240115.bak'

# The script will:
# 1. Stop BusinessPlus services on all TEST environment servers
# 2. Restore the IFAS and SYSCAT databases
# 3. Update security settings and permissions
# 4. Disable user accounts (except manager codes)
# 5. Update email addresses to dummy values
# 6. Restart all servers in the TEST environment
# 7. Send completion notification email
