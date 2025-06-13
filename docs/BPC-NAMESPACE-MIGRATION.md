# Migration Guide: BPlusDBRestore to BPC.DBRefresh

This guide helps you migrate from the old module names to the new BPC namespace.

## Module Name Changes

| Old Name | New Name |
|----------|----------|
| BPlusDBRestore | BPC.DBRefresh |
| PSBusinessPlusERP | BPC.Admin |

## Function Name Changes

All functions now use the `BPERP` prefix:

| Old Function | New Function |
|--------------|--------------|
| Copy-BPlusDashboardFiles | Copy-BPERPDashboardFiles |
| Get-BPlusDatabaseSettings | Get-BPERPDatabaseSettings |
| Restart-BPlusServers | Restart-BPERPServers |
| Restore-BPlusDatabase | Invoke-BPERPDatabaseRestore |
| Restore-BPlusDatabaseFiles | Invoke-BPERPDatabaseRestoreFiles |
| Send-BPlusNotification | Send-BPERPNotification |
| Set-BPlusConfiguration | Set-BPERPConfiguration |
| Set-BPlusDatabasePermissions | Set-BPERPDatabasePermissions |
| Set-BPlusDatabaseSettings | Set-BPERPDatabaseSettings |
| Stop-BPlusServices | Stop-BPERPServices |

## Migration Steps

### 1. Update Module Imports

**Old:**
```powershell
Import-Module BPlusDBRestore
Import-Module PSBusinessPlusERP
```

**New:**
```powershell
Import-Module BPC.DBRefresh
Import-Module BPC.Admin
```

### 2. Update Function Calls

**Old:**
```powershell
Restore-BPlusDatabase -BPEnvironment "TEST" -IfasFilePath $ifas -SyscatFilePath $syscat
```

**New:**
```powershell
Invoke-BPERPDatabaseRestore -BPEnvironment "TEST" -IfasFilePath $ifas -SyscatFilePath $syscat
```

### 3. Update Configuration Files

**Old:**
```ini
# hpsBPlusDBRestore.ini
```

**New:**
```ini
# hpsBPC.DBRefresh.ini
```

### 4. Update Scripts

Use this PowerShell script to update your scripts:

```powershell
# Update-ScriptsToBPC.ps1
$replacements = @{
    'BPlusDBRestore' = 'BPC.DBRefresh'
    'PSBusinessPlusERP' = 'BPC.Admin'
    'Copy-BPlusDashboardFiles' = 'Copy-BPERPDashboardFiles'
    'Get-BPlusDatabaseSettings' = 'Get-BPERPDatabaseSettings'
    'Restart-BPlusServers' = 'Restart-BPERPServers'
    'Restore-BPlusDatabase' = 'Invoke-BPERPDatabaseRestore'
    'Restore-BPlusDatabaseFiles' = 'Invoke-BPERPDatabaseRestoreFiles'
    'Send-BPlusNotification' = 'Send-BPERPNotification'
    'Set-BPlusConfiguration' = 'Set-BPERPConfiguration'
    'Set-BPlusDatabasePermissions' = 'Set-BPERPDatabasePermissions'
    'Set-BPlusDatabaseSettings' = 'Set-BPERPDatabaseSettings'
    'Stop-BPlusServices' = 'Stop-BPERPServices'
}

Get-ChildItem -Path . -Filter *.ps1 -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $updated = $false
    
    foreach ($old in $replacements.Keys) {
        if ($content -match $old) {
            $content = $content -replace $old, $replacements[$old]
            $updated = $true
        }
    }
    
    if ($updated) {
        $content | Set-Content $_.FullName
        Write-Host "Updated: $($_.FullName)"
    }
}
```

### 5. Update Scheduled Tasks

If you have scheduled tasks using the old module:

1. Export the task: `Export-ScheduledTask -TaskName "MyTask" | Out-File task.xml`
2. Update the XML file with new function names
3. Import the updated task: `Register-ScheduledTask -Xml (Get-Content task.xml | Out-String) -TaskName "MyTask"`

### 6. Update Documentation

Update any internal documentation, wikis, or runbooks to reflect:
- New module names
- New function names
- New repository URLs

## Backward Compatibility

The original `hpsBPlusDBRestore.ps1` script remains available as a wrapper for backward compatibility, but we recommend updating to the new module structure.

## Getting Help

If you encounter issues during migration:

1. Check the [FAQ](FAQ.md)
2. Review the [Troubleshooting Guide](TROUBLESHOOTING.md)
3. Open an [issue](https://github.com/businessplus-community/BPC.DBRefresh/issues)
4. Email: code@bpluscommunity.org

## Why the Change?

The BPC (BusinessPlus Community) namespace:
- Clearly indicates community ownership (not official PowerSchool)
- Provides a consistent naming pattern across all modules
- Is short and easy to type
- Avoids potential trademark concerns