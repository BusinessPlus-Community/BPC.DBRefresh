# Migration Guide: Script to Module

This guide helps you migrate from the original `hpsBPC.DBRefresh.ps1` script to the new modular structure.

## What Changed

The monolithic PowerShell script has been refactored into a proper PowerShell module with:
- Separate functions for each major operation
- Better error handling and logging
- Improved testability
- Module manifest for dependency management
- Pester tests for quality assurance

## File Structure Changes

### Old Structure
```
/BPC.DBRefresh/
├── hpsBPC.DBRefresh.ps1
└── hpsBPC.DBRefresh-sample.ini
```

### New Structure
```
/BPC.DBRefresh/
├── src/BPC.DBRefresh/       # Module source
│   ├── BPC.DBRefresh.psd1   # Module manifest
│   ├── BPC.DBRefresh.psm1   # Module loader
│   ├── Public/               # Public functions
│   └── Private/              # Private functions
├── config/                   # Configuration files
│   └── hpsBPC.DBRefresh-sample.ini
├── examples/                 # Usage examples
├── tests/                    # Pester tests
└── hpsBPC.DBRefresh.ps1     # Original script (kept for compatibility)
```

## Usage Changes

### Old Method (Still Supported)
```powershell
.\hpsBPC.DBRefresh.ps1 -BPEnvironment "TEST" -ifasFilePath "\\backup\ifas.bak" -syscatFilePath "\\backup\syscat.bak"
```

### New Method (Recommended)
```powershell
# Import the module
Import-Module .\src\BPC.DBRefresh

# Use the main function
Invoke-BPERPDatabaseRestore -BPEnvironment "TEST" -IfasFilePath "\\backup\ifas.bak" -SyscatFilePath "\\backup\syscat.bak"
```

### Using the Wrapper Script
For backward compatibility, use `Invoke-BPC.DBRefresh.ps1`:
```powershell
.\Invoke-BPC.DBRefresh.ps1 -BPEnvironment "TEST" -ifasFilePath "\\backup\ifas.bak" -syscatFilePath "\\backup\syscat.bak"
```

## Configuration File Location

The configuration file has moved:
- **Old**: `hpsBPC.DBRefresh.ini` (root directory)
- **New**: `config\hpsBPC.DBRefresh.ini`

Update any scripts or documentation that reference the configuration file path.

## New Features

### 1. Individual Function Access
You can now use individual functions:
```powershell
# Just stop services
Stop-BPERPServices -Config $config

# Just send notification
Send-BPERPNotification -Config $config -BackupFiles $files -StartTime $start -EndTime $end
```

### 2. Better Testing
```powershell
# Run module tests
Invoke-Pester .\tests\
```

### 3. Build Automation
```powershell
# Run all build tasks
.\build.ps1 -Task All

# Just analyze code
.\build.ps1 -Task Analyze
```

## Breaking Changes

1. **Configuration file location**: Now in `config\` directory
2. **Module import required**: Must import module before using functions
3. **Function names**: Main script functionality now in `Invoke-BPERPDatabaseRestore` function

## Deployment Considerations

### For Module Distribution
1. Use the build script to create a release package:
   ```powershell
   .\build.ps1 -Task Package
   ```

2. The package will include:
   - Module files
   - Documentation
   - Examples
   - Configuration templates

### For PowerShell Gallery
The module is ready for PowerShell Gallery publication:
1. Update version in `BPC.DBRefresh.psd1`
2. Run tests: `.\build.ps1 -Task Test`
3. Publish: `Publish-Module -Path .\src\BPC.DBRefresh`

## Troubleshooting

### Module Not Found
If you get "module not found" errors:
1. Check the module path: `$env:PSModulePath`
2. Import with full path: `Import-Module C:\path\to\src\BPC.DBRefresh`

### Configuration File Issues
1. Ensure INI file is in `config\` directory
2. Or specify path: `-ConfigPath "C:\custom\path\config.ini"`

### Permission Errors
The module requires the same permissions as the original script:
- SQL Server access
- Remote server access
- Service control permissions

## Support

For migration assistance:
- Open an issue on GitHub
- Email: code@bpluscommunity.org
- Check examples in `examples\` directory