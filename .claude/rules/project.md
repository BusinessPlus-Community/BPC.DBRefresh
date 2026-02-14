# Project: BPC.DBRefresh

**Last Updated:** 2026-02-14

## Overview

PowerShell module for automating BusinessPlus test environment database refresh operations. Uses JSON configuration for cross-platform compatibility, comprehensive error handling, and Pester tests following PowerShell best practices.

## Technology Stack

- **Language:** PowerShell 5.1+ (Desktop and Core compatible)
- **Platform:** Windows Server / Cross-platform (PowerShell Core)
- **Database:** Microsoft SQL Server
- **Module Version:** 2.1.0
- **Dependencies:**
  - PSLogging (logging framework)
  - dbatools (SQL Server database management)
  - MailKit/MimeKit (email notifications)

## Directory Structure

```
BPC.DBRefresh/
├── src/BPlusDBRefresh/
│   ├── BPlusDBRefresh.psd1      # Module manifest
│   ├── BPlusDBRefresh.psm1      # Module loader
│   ├── Public/                   # Exported functions
│   │   ├── Invoke-BPlusDBRefresh.ps1
│   │   ├── Get-BPlusConfiguration.ps1
│   │   └── Convert-IniToJson.ps1
│   ├── Private/                  # Internal helper functions
│   └── Resources/                # SQL queries, email templates
├── Tests/
│   ├── Unit/                     # Unit tests
│   └── Integration/              # Integration tests
├── bpcBPlusDBRefresh-sample.json # Sample JSON configuration
├── bpcBPlusDBRefresh-sample.ini  # Legacy INI sample (v1.x)
├── PSScriptAnalyzerSettings.psd1 # Code quality rules
└── README.md

## Key Files

- **Module Manifest:** `src/BPlusDBRefresh/BPlusDBRefresh.psd1` - Module metadata, dependencies, exports
- **Module Root:** `src/BPlusDBRefresh/BPlusDBRefresh.psm1` - Auto-loads Public/Private functions
- **Configuration:** `bpcBPlusDBRefresh.json` (JSON format, v2.0+)
- **Legacy Config:** `bpcBPlusDBRefresh.ini` (supported via Convert-IniToJson)
- **PSScriptAnalyzer Config:** `PSScriptAnalyzerSettings.psd1` - OTBS style, 4-space indent

## Public Functions

| Function | Description |
|----------|-------------|
| `Invoke-BPlusDBRefresh` | Main entry point - orchestrates database refresh workflow |
| `Get-BPlusConfiguration` | Loads and validates JSON configuration for target environment |
| `Convert-IniToJson` | Migration utility - converts legacy INI config to JSON |

## Module Parameters (Invoke-BPlusDBRefresh)

| Parameter | Required | Description |
|-----------|----------|-------------|
| `BPEnvironment` | Yes | Target environment name (e.g., TEST1) |
| `aspnetFilePath` | No | Path to aspnet database backup |
| `ifasFilePath` | Yes | Path to ifas/bplus database backup |
| `syscatFilePath` | Yes | Path to syscat database backup |
| `testingMode` | No | Enable extra test accounts |
| `restoreDashboards` | No | Copy dashboard files |

## Refresh Workflow

1. Load required PowerShell modules (PSLogging, dbatools)
2. Parse JSON configuration for target environment
3. Display configuration summary and prompt for confirmation
4. Stop BusinessPlus services on environment servers
5. Capture existing connection data from databases
6. Restore databases (aspnet, syscat, ifas) with file mapping
7. Restore environment connection information
8. Configure SQL Server security (drop/create users, set permissions)
9. Disable workflows and user accounts (except allowed manager codes)
10. Update NUUPAUSY text and dashboard URL
11. Optionally restore dashboard files
12. Reboot environment servers
13. Send email notification on completion

## JSON Configuration Structure

```json
{
  "sqlServer": { "TEST1": "SQL-SERVER\\INSTANCE" },
  "database": { "TEST1": "BPlusDB" },
  "syscat": { "TEST1": "BPlusSyscat" },
  "aspnet": { "TEST1": "AspnetDB" },
  "filepathData": { "TEST1": "D:\\SQLData" },
  "environmentServers": { "TEST1": ["SERVER1", "SERVER2"] },
  "SMTP": { "Server": "smtp.example.com", "From": "notify@example.com" }
}
```

See `bpcBPlusDBRefresh-sample.json` for complete configuration template.

## Development Commands

```powershell
# Import module
Import-Module ./src/BPlusDBRefresh/BPlusDBRefresh.psd1

# Run all tests
Invoke-Pester ./Tests

# Run unit tests only
Invoke-Pester ./Tests/Unit

# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1

# Migrate INI to JSON
Convert-IniToJson -IniPath ./config.ini -JsonPath ./config.json
```

## Usage Examples

```powershell
# Import the module
Import-Module ./src/BPlusDBRefresh

# Basic restore
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak"

# With testing mode and dashboard restore
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak" `
  -testingMode -restoreDashboards

# Migrate legacy INI config to JSON
Convert-IniToJson -IniPath ./bpcBPlusDBRefresh.ini -JsonPath ./bpcBPlusDBRefresh.json
```

## Testing

- **Unit Tests:** Test individual functions in isolation (Tests/Unit/)
- **Integration Tests:** Test end-to-end workflow (Tests/Integration/)
- **Framework:** Pester (PowerShell testing framework)
- **Run tests:** `Invoke-Pester ./Tests`

## Code Quality

- **PSScriptAnalyzer:** Enforces PoshCode PowerShell Practice and Style Guide
- **Brace Style:** OTBS (One True Brace Style) - opening brace on same line
- **Indentation:** 4 spaces (no tabs)
- **Help:** Comment-based help required for all exported functions
- **Run analysis:** `Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1`

## Version History

- **v2.1.0** - Migrated from INI to JSON configuration, removed PsIni dependency
- **v2.0.0** - Refactored to module structure, added Pester tests, externalized SQL/templates
- **v1.x** - Original monolithic script with INI configuration

## Additional Context

- Designed for BusinessPlus Community BusinessPlus environments
- Handles database security transition from production to test
- Disables production workflows to prevent test environment side effects
- Sanitizes email addresses to prevent accidental notifications
- Cross-platform compatible (PowerShell Desktop 5.1+ and Core 7+)
