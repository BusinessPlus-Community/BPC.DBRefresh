# Troubleshooting Guide

This guide helps diagnose and resolve common issues with the BusinessPlus Test Environment Refresh tool.

## Diagnostic Steps

### 1. Enable Verbose Logging

```powershell
$VerbosePreference = 'Continue'
Invoke-BPERPDatabaseRestore -BPEnvironment "TEST" -Verbose -IfasFilePath $ifas -SyscatFilePath $syscat
```

### 2. Check Prerequisites

Run this diagnostic script:
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check required modules
@('PSLogging', 'dbatools', 'PsIni') | ForEach-Object {
    $module = Get-Module -ListAvailable -Name $_
    if ($module) {
        Write-Host "✓ $_ v$($module.Version) installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $_ not installed" -ForegroundColor Red
    }
}

# Test SQL connectivity
$config = Get-BPlusEnvironmentConfig -Environment "TEST" -ConfigPath ".\config\hpsBPC.DBRefresh.ini"
Test-DbaConnection -SqlInstance $config.SQLInstance
```

## Common Issues and Solutions

### Module Import Failures

#### Symptom
```
Import-Module : The specified module 'BPC.DBRefresh' was not loaded because no valid module file was found
```

#### Solution
```powershell
# Check module path
$env:PSModulePath -split ';'

# Import with full path
Import-Module "C:\full\path\to\src\BPC.DBRefresh" -Force

# Or add to PSModulePath
$env:PSModulePath += ";C:\path\to\BPC.DBRefresh\src"
```

### Database Connection Issues

#### Symptom
```
Failed to connect to SQL Server 'SQLSERVER\INSTANCE'
```

#### Solutions

1. **Check SQL Server service**:
```powershell
Get-Service -ComputerName SQLSERVER -Name "MSSQL*"
```

2. **Verify SQL authentication**:
```powershell
# Test with SQL authentication
Test-DbaConnection -SqlInstance "SQLSERVER\INSTANCE" -SqlCredential (Get-Credential)

# Test with Windows authentication
Test-DbaConnection -SqlInstance "SQLSERVER\INSTANCE"
```

3. **Check firewall rules**:
```powershell
Test-NetConnection -ComputerName SQLSERVER -Port 1433
```

### Permission Denied Errors

#### Symptom
```
Access is denied
Cannot open database "SYSCAT" requested by the login
```

#### Solutions

1. **Verify SQL permissions**:
```sql
-- Check current user permissions
SELECT 
    p.permission_name,
    p.state_desc,
    p.class_desc,
    p.major_id
FROM sys.server_permissions p
WHERE p.grantee_principal_id = USER_ID()

-- Check sysadmin role
SELECT IS_SRVROLEMEMBER('sysadmin')
```

2. **Check Windows permissions**:
```powershell
# Verify service account permissions
Get-Acl "\\server\share\backup.bak" | Format-List
```

### Service Management Issues

#### Symptom
```
Cannot stop service 'BusinessPlus' on computer 'SERVER1'
```

#### Solutions

1. **Check service status**:
```powershell
Get-Service -ComputerName SERVER1 -Name "BusinessPlus*" | 
    Select-Object Name, Status, StartType, DependentServices
```

2. **Check for dependent services**:
```powershell
Get-Service -ComputerName SERVER1 -Name "BusinessPlus" | 
    Select-Object -ExpandProperty DependentServices
```

3. **Force stop with dependencies**:
```powershell
Get-Service -ComputerName SERVER1 -Name "BusinessPlus" -DependentServices | 
    Stop-Service -Force
```

### Database Restore Failures

#### Symptom
```
Restore-DbaDatabase : The backup set holds a backup of a database other than the existing database
```

#### Solutions

1. **Use WITH REPLACE option** (already included in module)

2. **Check backup file**:
```powershell
# Verify backup file
Read-DbaBackupHeader -SqlInstance $instance -Path "\\path\to\backup.bak"

# Test restore
Test-DbaBackupInformation -SqlInstance $instance -Path "\\path\to\backup.bak"
```

3. **Check disk space**:
```powershell
# Check available space
Get-DbaDiskSpace -ComputerName SQLSERVER

# Check database sizes
Get-DbaDatabase -SqlInstance $instance | 
    Select-Object Name, SizeMB, SpaceAvailable
```

### Post-Restore Configuration Errors

#### Symptom
```
Invalid column name 'NUVALUE'
String or binary data would be truncated
```

#### Solutions

1. **Verify table schema**:
```sql
-- Check table structure
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'NUUPGDST'
```

2. **Check data compatibility**:
```sql
-- Find problematic data
SELECT LEN(NUVALUE) as Length, NUVALUE 
FROM NUUPGDST 
WHERE LEN(NUVALUE) > 255
```

### Email Notification Failures

#### Symptom
```
Send-MailMessage : Unable to connect to the remote server
```

#### Solutions

1. **Test SMTP connectivity**:
```powershell
Test-NetConnection -ComputerName smtp.server.com -Port 25
```

2. **Test with simple email**:
```powershell
Send-MailMessage -To "test@domain.com" -From "noreply@domain.com" `
    -Subject "Test" -Body "Test message" -SmtpServer "smtp.server.com" `
    -Port 25 -UseSsl:$false
```

3. **Check TLS requirements**:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

### Server Restart Issues

#### Symptom
```
Restart-Computer : The system shutdown cannot be initiated
```

#### Solutions

1. **Check WinRM connectivity**:
```powershell
Test-WSMan -ComputerName SERVER1
```

2. **Use alternative restart method**:
```powershell
# Using WMI
Get-WmiObject -Class Win32_OperatingSystem -ComputerName SERVER1 | 
    ForEach-Object { $_.Win32Shutdown(6) }

# Using shutdown.exe
Invoke-Command -ComputerName SERVER1 -ScriptBlock { 
    shutdown.exe /r /t 60 /f 
}
```

## Performance Issues

### Slow Database Restores

1. **Check network speed**:
```powershell
# Test file copy speed
Measure-Command {
    Copy-Item "\\backup\server\test.file" "C:\temp\" -Force
}
```

2. **Use backup compression**:
```sql
BACKUP DATABASE [IFAS] TO DISK = 'C:\Backup\IFAS.bak' 
WITH COMPRESSION, STATS = 10
```

3. **Consider local staging**:
```powershell
# Copy backup locally first
Copy-Item "\\remote\backup.bak" "D:\LocalBackup\" -Force
Restore-DbaDatabase -Path "D:\LocalBackup\backup.bak" ...
```

### Script Timeout Issues

1. **Increase timeout values**:
```powershell
# Set SQL command timeout
$PSDefaultParameterValues['Invoke-DbaQuery:CommandTimeout'] = 0

# Set service timeout
$service.WaitForStatus('Stopped', '00:10:00')
```

## Debug Mode

Enable full debugging:
```powershell
$DebugPreference = 'Continue'
Set-PSDebug -Trace 2
Invoke-BPERPDatabaseRestore -BPEnvironment "TEST" -Debug ...
Set-PSDebug -Trace 0
```

## Getting Help

If these solutions don't resolve your issue:

1. **Collect diagnostic information**:
```powershell
# System info
Get-ComputerInfo | Out-File diagnostic.txt

# Module info  
Get-Module BPC.DBRefresh -ListAvailable | Out-File -Append diagnostic.txt

# Error details
$Error[0] | Format-List * -Force | Out-File -Append diagnostic.txt
```

2. **Open an issue** on [GitHub](https://github.com/businessplus-community/BPC.DBRefresh/issues) with:
   - Diagnostic information
   - Full error messages
   - Steps to reproduce
   - Environment details

3. **Contact support** at code@bpluscommunity.org