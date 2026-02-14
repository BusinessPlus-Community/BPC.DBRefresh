# BusinessPlus Test Environment Refresh

[![GitHub release](https://img.shields.io/github/v/release/BusinessPlus-Community/BPC.DBRefresh?logo=github)](https://github.com/BusinessPlus-Community/BPC.DBRefresh/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)

PowerShell module for automating BusinessPlus test environment database refresh operations. Handles service management, database restoration, permission configuration, and email notifications with JSON-based configuration for cross-platform compatibility.

## Features

- **Automated Database Restore** - Restore aspnet, syscat, and ifas databases from production backups
- **Service Management** - Stop and restart BusinessPlus services across environment servers
- **Permission Configuration** - Apply SQL Server permissions using externalized SQL scripts
- **User Account Sanitization** - Disable production accounts, enable test users, sanitize email addresses
- **Email Notifications** - HTML email notifications with customizable templates
- **JSON Configuration** - Cross-platform JSON config (v2.1.0+) with automatic INI migration
- **Comprehensive Testing** - Pester unit and integration tests
- **Cross-Platform Support** - PowerShell Desktop 5.1+ and Core 7+

## Requirements

- PowerShell 5.1 or higher (Desktop or Core)
- SQL Server environment with appropriate permissions
- Required PowerShell modules (auto-installed from PowerShell Gallery):
  - [PSLogging](https://www.powershellgallery.com/packages/PSLogging) - Structured logging framework
  - [dbatools](https://www.powershellgallery.com/packages/dbatools) - SQL Server database operations
- MailKit/MimeKit (auto-installed if missing)

## Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/BusinessPlus-Community/BPC.DBRefresh.git
cd BPC.DBRefresh

# Import the module
Import-Module ./src/BPlusDBRefresh/BPlusDBRefresh.psd1
```

### Verify Installation

```powershell
Get-Module BPlusDBRefresh
Get-Command -Module BPlusDBRefresh
```

## Quick Start

### 1. Create Configuration File

Copy the sample configuration and customize it for your environment:

```powershell
Copy-Item bpcBPlusDBRefresh-sample.json bpcBPlusDBRefresh.json
```

Edit `bpcBPlusDBRefresh.json` with your environment settings (SQL Server instances, database names, SMTP settings, etc.).

### 2. Run Database Refresh

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak"
```

The script will:
- Display a configuration review
- Prompt for confirmation
- Execute the 13-step refresh workflow
- Send email notification on completion

## Breaking Changes - Migration Guide

**v2.1.0 introduced new file naming conventions.** If upgrading from v2.0.x or earlier:

### Step 1: Backup Your Configuration

```powershell
Copy-Item hpsBPlusDBRestore.json hpsBPlusDBRestore.json.backup
```

### Step 2: Rename Configuration Files

```powershell
# Rename JSON configuration
Rename-Item hpsBPlusDBRestore.json bpcBPlusDBRefresh.json

# Rename INI configuration (if using legacy format)
Rename-Item hpsBPlusDBRestore.ini bpcBPlusDBRefresh.ini
```

### Step 3: Update Wrapper Scripts

If you have any automation scripts that reference the old filename, update them to use the new names:
- `hpsBPlusDBRestore.json` → `bpcBPlusDBRefresh.json`
- `hpsBPlusDBRestore.ini` → `bpcBPlusDBRefresh.ini`
- `hpsBPlusDBRestore.log` → `bpcBPlusDBRefresh.log`

The module will automatically use the new filenames for defaults and logging.

## Configuration

The module uses JSON configuration files with [JSON Schema validation](bpcBPlusDBRefresh.schema.json) for IDE autocomplete and error checking. See [bpcBPlusDBRefresh-sample.json](bpcBPlusDBRefresh-sample.json) for a complete template.

### Configuration Structure

```json
{
  "$schema": "./bpcBPlusDBRefresh.schema.json",
  "environments": {
    "TEST1": {
      "sqlServer": "SQL-SERVER\\INSTANCE",
      "database": "BPlusDB",
      "syscat": "BPlusSyscat",
      "aspnet": "AspnetDB",
      "filepathData": "D:\\SQLData",
      "filepathLog": "D:\\SQLLogs",
      "filepathImages": "I:\\SQLImages",
      "fileDriveData": [
        "ifas:Data:ifastest1.MDF",
        "ifas_log:Log:ifastest1_log.LDF"
      ],
      "fileDriveSyscat": [
        "syscat:Data:syscattest1.MDF",
        "syscat_log:Log:syscattest1_log.LDF"
      ],
      "fileDriveAspnet": [
        "aspnetprod:Data:aspnettest1.MDF",
        "aspnetprod_log:Log:aspnettest1_log.LDF"
      ],
      "environmentServers": ["SERVER1", "SERVER2"],
      "ipcDaemon": "BusinessPlusDaemon",
      "nuupausy": "TEST Environment",
      "iusrSource": "DOMAIN\\IUSRProduction",
      "iusrDestination": "DOMAIN\\IUSRTest",
      "adminSource": "DOMAIN\\AdminProd",
      "adminDestination": "DOMAIN\\AdminTest",
      "dboSource": "DOMAIN\\DBOProd",
      "dboDestination": "DOMAIN\\DBOTest",
      "dummyEmail": "test@example.com",
      "managerCodes": ["ADMIN1", "ADMIN2"],
      "testingModeCodes": ["TESTER1", "TESTER2"],
      "dashboardUrl": "https://test-dashboard.example.com",
      "dashboardFiles": "\\\\prod-server\\dashboards:\\\\test-server\\dashboards"
    }
  },
  "smtp": {
    "host": "smtp.example.com",
    "port": 587,
    "ssl": false,
    "replyToEmail": "noreply@example.com",
    "notificationEmail": "team@example.com"
  }
}
```

### Key Configuration Sections

| Section | Purpose |
|---------|---------|
| `environments` | Container for all environment-specific configurations |
| `environments.<ENV>.sqlServer` | SQL Server instance for this environment |
| `environments.<ENV>.database`, `syscat`, `aspnet` | Database names for this environment |
| `environments.<ENV>.filepathData`, `filepathLog`, `filepathImages` | SQL Server file paths for database restore |
| `environments.<ENV>.fileDriveData`, `fileDriveSyscat`, `fileDriveAspnet` | Logical file name mappings for database restore |
| `environments.<ENV>.environmentServers` | BusinessPlus application servers to manage |
| `environments.<ENV>.iusrSource/Destination` | Service account mapping (production → test) |
| `environments.<ENV>.adminSource/Destination` | Admin account mapping (production → test) |
| `environments.<ENV>.dboSource/Destination` | DBO account mapping (production → test) |
| `environments.<ENV>.managerCodes` | User accounts to keep active in test environment |
| `environments.<ENV>.testingModeCodes` | Additional accounts to enable with `-testingMode` switch |
| `environments.<ENV>.dashboardUrl` | Dashboard URL for this environment |
| `environments.<ENV>.dashboardFiles` | Dashboard file copy settings (source:destination) |
| `smtp` | Email notification settings (applies to all environments) |
| `smtp.host`, `smtp.port` | SMTP server connection settings |
| `smtp.replyToEmail`, `smtp.notificationEmail` | Email addresses for notifications |

### Migrating from v1.x INI Configuration

If you have an existing INI configuration file from v1.x, migrate it to JSON:

```powershell
Convert-IniToJson -IniPath ./bpcBPlusDBRefresh.ini -OutputPath ./bpcBPlusDBRefresh.json
```

The migration utility preserves all settings and creates a properly formatted JSON file.

## Usage

### Basic Database Refresh

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak"
```

### With Optional ASP.NET Database

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -aspnetFilePath "\\backup\aspnet.bak" `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak"
```

### Enable Testing Mode (Activate Extra Test Accounts)

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak" `
  -testingMode
```

This enables user accounts specified in the `TestingMode` section of the configuration.

### Restore Dashboard Files

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak" `
  -restoreDashboards
```

### Custom Configuration File

```powershell
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak" `
  -ConfigurationPath "C:\Custom\config.json"
```

### Load Configuration Without Executing Refresh

```powershell
$config = Get-BPlusConfiguration -Path ./bpcBPlusDBRefresh.json -Environment TEST1
$config.DatabaseServer
$config.Servers
```

## Refresh Workflow

The module performs these operations in sequence:

1. **Load Required Modules** - Import PSLogging and dbatools
2. **Parse Configuration** - Load and validate JSON configuration for target environment
3. **Configuration Review** - Display settings and prompt for user confirmation
4. **Stop Services** - Stop BusinessPlus IPC daemon on all environment servers
5. **Backup Connection Data** - Capture existing database connection configuration
6. **Restore Databases** - Restore aspnet/syscat/ifas from backup files with file mapping
7. **Restore Connections** - Re-apply saved connection configuration to restored databases
8. **Configure Permissions** - Execute SQL scripts to set database permissions
9. **Disable Workflows** - Disable production workflows to prevent test environment side effects
10. **Sanitize User Accounts** - Disable production users, enable test users, replace email addresses
11. **Update Environment Indicators** - Set NUUPAUSY text and dashboard URL
12. **Dashboard Files** *(optional)* - Copy dashboard files from source to destination
13. **Reboot and Notify** - Restart environment servers and send completion email

## Module Architecture

```
src/BPlusDBRefresh/
├── BPlusDBRefresh.psd1          # Module manifest (v2.1.0)
├── BPlusDBRefresh.psm1          # Module root - auto-loads functions
├── Public/                       # Exported functions
│   ├── Invoke-BPlusDBRefresh.ps1       # Main entry point
│   ├── Get-BPlusConfiguration.ps1      # Config parsing and validation
│   └── Convert-IniToJson.ps1           # INI→JSON migration utility
├── Private/                      # Internal helper functions (15 total)
│   ├── Backup-DatabaseConnectionInfo.ps1
│   ├── Restore-BPlusDatabase.ps1
│   ├── Set-DatabasePermissions.ps1
│   ├── Send-CompletionNotification.ps1
│   └── ... (11 more)
└── Resources/                    # SQL queries and templates
    ├── SQL/                      # Database operation scripts
    │   ├── Set-IfasPermissions.sql
    │   ├── Set-SyscatPermissions.sql
    │   ├── Set-AspnetPermissions.sql
    │   └── Disable-Workflows.sql
    └── Templates/
        └── CompletionEmail.html  # Email notification template
```

## Development

### Running Tests

```powershell
# Run all tests (unit + integration)
Invoke-Pester ./Tests

# Run unit tests only (isolated functions)
Invoke-Pester ./Tests/Unit

# Run integration tests only (full workflow with mocks)
Invoke-Pester ./Tests/Integration

# Run specific test file
Invoke-Pester ./Tests/Unit/Get-BPlusConfiguration.Tests.ps1

# Run with code coverage
Invoke-Pester ./Tests -CodeCoverage ./src/**/*.ps1
```

### Code Quality

```powershell
# Run PSScriptAnalyzer (enforces OTBS style, 4-space indent)
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1

# Auto-fix fixable issues
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1 -Fix
```

### Code Standards

This module follows the [PoshCode PowerShell Practice and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle):

- **OTBS Brace Style** - Opening brace on same line
- **4-Space Indentation** - No tabs
- **Comment-Based Help** - Required for all exported functions
- **Approved Verbs** - Use `Get-Verb` to verify
- **No Aliases** - Full cmdlet names in scripts

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2021-2026 BusinessPlus Community. All rights reserved.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

When contributing:
- Follow the existing code style (OTBS, 4-space indent)
- Add comment-based help to new functions
- Include Pester tests for new functionality
- Run `Invoke-ScriptAnalyzer` before submitting
- Update documentation for user-facing changes

## Version History

See [GitHub Releases](https://github.com/BusinessPlus-Community/BPC.DBRefresh/releases) for full release notes.

### v2.1.0 (Current)
- Migrated from INI to JSON configuration format for cross-platform compatibility
- Removed PsIni module dependency (uses native `ConvertFrom-Json`)
- Added `Convert-IniToJson` utility for migrating existing configurations
- Automatic INI detection with migration prompt in `Get-BPlusConfiguration`

### v2.0.0
- Complete refactor to PowerShell module structure
- Externalized SQL queries and HTML email templates to Resources/
- Comprehensive error handling with Try/Catch blocks
- Added Pester unit and integration tests
- MailKit integration for email notifications (Send-MailMessage deprecated)
- Follows PoshCode PowerShell Practice and Style Guide

### v1.x
- Original monolithic script (`hpsBPlusDBRestore.ps1`)
- INI-based configuration
- Basic error handling

## Support

For issues and questions:
- Open an issue on [GitHub](https://github.com/BusinessPlus-Community/BPC.DBRefresh/issues)
- See [CLAUDE.md](CLAUDE.md) for AI assistant guidance when working with this codebase

## Acknowledgments

Designed for BusinessPlus Community environments.
