# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the BPC.DBRefresh module - a PowerShell automation tool for refreshing BusinessPlus test environments with production database backups. The module handles database restoration, security configuration, and environment-specific settings.

This module is part of the BPC namespace, which provides modular PowerShell tools for managing various aspects of BusinessPlus ERP/HR/PY systems.

## Module Namespace Strategy

The BusinessPlus Community uses a namespace approach for PowerShell modules:

- `BPC.DBRefresh` - Database refresh operations (this module)
- `BPC.Admin` - Administrative functions
- `BPC.Reports` - Report generation/fetching
- `BPC.Security` - User/permission management
- `BPC.Finance` - Financial operations
- `BPC.HR` - Human resources functions

## Project Structure

```
src/BPC.DBRefresh/         # PowerShell module
├── Public/                 # Public functions
├── Private/                # Internal functions
├── BPC.DBRefresh.psd1     # Module manifest
└── BPC.DBRefresh.psm1     # Module file
config/                     # Configuration files
examples/                   # Usage examples
tests/                      # Pester tests
docs/                       # Documentation
.github/                    # GitHub Actions and templates
hpsBPC.DBRefresh.ps1       # Original script (backward compatibility)
```

## Commands

### Running the Module

```powershell
# Import module
Import-Module .\src\BPC.DBRefresh

# Primary command
Invoke-BPERPDatabaseRestore -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# Build and test
.\build.ps1 -Task All

# Run tests
Invoke-Pester -Path .\tests

# Lint code
.\build.ps1 -Task Analyze
```

### Parameters

- `BPEnvironment`: Target environment name (required)
- `ifasFilePath`: Path to IFAS database backup file (required)
- `syscatFilePath`: Path to SYSCAT database backup file (required)
- `aspnetFilePath`: Path to ASPNET database backup file (optional)
- `testingMode`: Enable additional test accounts (optional)
- `restoreDashboards`: Copy dashboard files to environment (optional)

### PowerShell Module Requirements

The module requires these PowerShell modules:

- PSLogging 2.2.0+
- dbatools 1.0.0+
- PsIni 3.1.2+

## Development Standards

### Function Naming Convention

Use consistent BPERP prefix for all functions:
- `Invoke-BPERPDatabaseRestore` (main function)
- `Get-BPERPDatabaseSettings`
- `Set-BPERPDatabasePermissions`
- `Stop-BPERPServices`
- `Restart-BPERPServers`

### Testing

```powershell
# Run tests
Invoke-Pester -Path .\tests

# Run with code coverage
.\build.ps1 -Task Test
```

### CI/CD

The project uses GitHub Actions for:
- Continuous Integration (CI) on all platforms
- Security scanning with CodeQL
- Automated releases to PowerShell Gallery
- Pre-commit hooks for code quality

## Architecture

### Configuration Structure

The module uses INI files for environment configuration (`config/hpsBPC.DBRefresh-sample.ini`):

- SQL Server instances and database mappings
- Server lists per environment
- File paths for data, logs, and images
- SMTP settings for notifications
- User permissions and security mappings

### Workflow Sequence

1. **Initialization**: Loads modules, parses INI configuration
2. **Service Management**: Stops BusinessPlus services across environment servers
3. **Database Operations**:
   - Backs up existing connection configurations
   - Restores databases from provided backup files
   - Reconfigures permissions and security settings
4. **Post-Restore Tasks**:
   - Disables user accounts (preserves manager codes)
   - Updates email addresses to dummy values
   - Disables non-essential workflows
   - Updates NUUPAUSY display text
5. **Environment Restart**: Reboots all servers
6. **Notification**: Sends completion email

### Key Technical Details

- **Logging**: All operations logged to `hpsBPC.DBRefresh.log`
- **Security**: Contains operations that modify database permissions and user access
- **Dependencies**: Requires SQL Server access and appropriate permissions
- **Email**: Uses MailKit assemblies for SMTP notifications

## Contributing

Follow the standards in CONTRIBUTING.md:
1. Fork the repository
2. Create feature branch from `main`
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## Migration Status

### Completed Tasks
- ✅ Module renamed from `BPlusDBRestore` to `BPC.DBRefresh`
- ✅ All functions renamed to use `BPERP` prefix
- ✅ Configuration files updated to `hpsBPC.DBRefresh.ini`
- ✅ All documentation updated with new names
- ✅ Backward compatibility maintained via wrapper scripts
- ✅ GitHub Actions and CI/CD pipelines configured
- ✅ Pre-commit hooks and code quality tools added

### Pending Tasks
- ⏳ Create pull request to merge `feature/module-conversion` to `main`
- ⏳ Rename GitHub repository from `bp-test-env-refresh` to `BPC.DBRefresh`
- ⏳ Update PowerShell Gallery package name when published
- ⏳ Rename local folder from `bp-test-env-refresh` to `BPC.DBRefresh`

### Related Projects
- `PSBusinessPlusERP` → `BPC.Admin` (migration scripts provided in this repo)
- Future modules will follow the `BPC.*` namespace pattern

## Migration Resources

- **MIGRATION-SUMMARY.md** - Complete status of the namespace migration
- **docs/BPC-NAMESPACE-MIGRATION.md** - User migration guide
- **comprehensive-rename-to-bpc-admin.ps1** - Script to migrate PSBusinessPlusERP
- **bpc-admin-migration-commands.txt** - Manual migration commands

## Repository Renaming

After closing all sessions using this folder:
1. Rename folder: `mv bp-test-env-refresh BPC.DBRefresh`
2. Update git remote: `git remote set-url origin https://github.com/businessplus-community/BPC.DBRefresh.git`
3. Update GitHub repository name in Settings → General

## Future Development

This module follows the BPC (BusinessPlus Community) namespace strategy. Additional modules in the BPC namespace will be developed to provide comprehensive PowerShell tooling for BusinessPlus ERP/HR/PY systems.

### BPC Namespace Benefits
- **Clear Community Attribution**: BPC = BusinessPlus Community
- **Short and Memorable**: Only 3 characters
- **No Trademark Concerns**: Clearly not official PowerSchool
- **Consistent Pattern**: All modules follow BPC.* naming