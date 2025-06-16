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
BPC.DBRefresh/             # PowerShell module (root level, not in src/)
├── Public/                 # Public functions
├── Private/                # Internal functions
├── Classes/                # PowerShell classes (if needed)
├── BPC.DBRefresh.psd1     # Module manifest
└── BPC.DBRefresh.psm1     # Module file
config/                     # Configuration files
examples/                   # Usage examples
tests/                      # Pester tests
├── Unit/                   # Unit tests
├── Public/                 # Public function tests
└── PSScriptAnalyzerSettings.psd1  # Consolidated analyzer settings
docs/                       # Documentation
├── en-US/                  # PowerShell help files
├── ARCHITECTURE.md         # System architecture documentation
├── RELEASES.md            # Release history
├── ROADMAP.md             # Future development plans
└── TROUBLESHOOTING.md     # Common issues and solutions
.github/                    # GitHub Actions and templates
BPC.DBRefresh.ps1          # Original script (backward compatibility)
Invoke-BPC.DBRefresh.ps1   # Wrapper for backward compatibility
```

## Commands

### Running the Module

```powershell
# Import module
Import-Module .\BPC.DBRefresh

# Primary command
Invoke-BPERPDatabaseRestore -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# Install dependencies
.\build.ps1 -Bootstrap
# or
.\Requirements.ps1 -NuGetBootstrap

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
- dbatools 2.1.31+
- PsIni 3.1.2+

These are automatically installed by running:
- `.\build.ps1 -Bootstrap` (recommended)
- `.\Requirements.ps1 -NuGetBootstrap`

Development also requires:
- Pester 5.0.0+ (for testing)
- PSScriptAnalyzer 1.24.0+ (for linting)

### VSCode Configuration

The repository includes standardized VSCode configuration:
- **Theme**: GitHub Dark Dimmed (organization standard)
- **Icon Theme**: Material Icon Theme (organization standard)
- **Formatting**: PowerShell Best Practices (OTBS style)
- **Indentation**: 4 spaces (PowerShell standard)
- **Extensions**: Minimal set for performance (PowerShell, Markdown, EditorConfig)
- **Explorer**: Shows `./context/` folder despite being gitignored
- **Terminal**: WSL (Debian) as default terminal on Windows
- **PSScriptAnalyzer**: Settings located in `tests/PSScriptAnalyzerSettings.psd1`

### CI/CD Pipeline

The project uses GitHub Actions with separated jobs:
1. **Lint (Style)**: Runs on Ubuntu for fast style checking
2. **Compatibility Check**: Runs on Windows for PowerShell compatibility analysis (non-blocking)
3. **Test**: Full matrix testing across Windows, Ubuntu, macOS with PowerShell 5.1, 7.2, 7.3, 7.4
4. **Build**: Creates the module package
5. **Documentation**: Generates help documentation

**Note**: PSScriptAnalyzer compatibility rules are isolated to Windows to prevent CI failures on other platforms.

## Development Standards

### Build System

The project uses PowerShellBuild module for standardized builds:
- Minimal psake configuration leveraging PowerShellBuild defaults
- Consistent with other BPC namespace modules (e.g., BPC.Admin)
- Module structure at root level (not in src/ directory)
- Supports both NuGet and PowerShell Gallery publishing

### Function Naming Convention

Use consistent BPERP prefix for all functions:
- `Invoke-BPERPDatabaseRestore` (main function)
- `Get-BPERPDatabaseSettings`
- `Set-BPERPDatabasePermissions`
- `Stop-BPERPServices`
- `Restart-BPERPServers`

Private functions also follow BPERP naming:
- `Get-BPERPEnvironmentConfig`
- `Show-BPERPConfiguration`
- `Write-BPERPLog`

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

The module uses INI files for environment configuration (`config/BPC.DBRefresh-sample.ini`):

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

- **Logging**: All operations logged to `BPC.DBRefresh.log`
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
- ✅ Configuration files updated to `BPC.DBRefresh.ini`
- ✅ All documentation updated with new names
- ✅ Backward compatibility maintained via wrapper scripts
- ✅ GitHub Actions and CI/CD pipelines configured
- ✅ Pre-commit hooks and code quality tools added
- ✅ GitHub repository renamed from `bp-test-env-refresh` to `BPC.DBRefresh`
- ✅ Dependency management system implemented (Requirements.ps1)
- ✅ Cross-platform compatible tests created
- ✅ CI/CD pipeline fixed for all platforms
- ✅ VSCode configuration standardized for organization
- ✅ Removed temporary migration scripts
- ✅ Fixed PSScriptAnalyzer CI issues with separated jobs
- ✅ Implemented BPC.Admin build patterns using PowerShellBuild module
- ✅ Reorganized module structure from src/ to root directory
- ✅ Fixed all test failures and skipped integration tests requiring parameters
- ✅ Consolidated PSScriptAnalyzer settings into single file
- ✅ Configured WSL (Debian) as default terminal for Windows
- ✅ Organized documentation files according to GitHub best practices

### Pending Tasks
- ⏳ Create pull request to merge `feature/module-conversion` to `main`
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

## Repository Information

The GitHub repository has been renamed to `BPC.DBRefresh` and is available at:
https://github.com/BusinessPlus-Community/BPC.DBRefresh

To update your local folder name:
1. Close all sessions using this folder
2. Rename folder: `mv bp-test-env-refresh BPC.DBRefresh`
3. The git remote URL has been automatically updated by GitHub

## Future Development

This module follows the BPC (BusinessPlus Community) namespace strategy. Additional modules in the BPC namespace will be developed to provide comprehensive PowerShell tooling for BusinessPlus ERP/HR/PY systems.

### BPC Namespace Benefits
- **Clear Community Attribution**: BPC = BusinessPlus Community
- **Short and Memorable**: Only 3 characters
- **No Trademark Concerns**: Clearly not official PowerSchool
- **Consistent Pattern**: All modules follow BPC.* naming