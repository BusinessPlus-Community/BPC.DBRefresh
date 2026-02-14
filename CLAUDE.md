# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

BPlusDBRefresh is a PowerShell module (v2.1.0) that automates BusinessPlus test environment database refresh operations. It follows the PoshCode PowerShell Practice and Style Guide with a modular architecture, externalized SQL/templates, and comprehensive Pester tests.

## Module Architecture

**Key Principle:** Code lives in functions, data lives in Resources.

```
src/BPlusDBRefresh/
├── BPlusDBRefresh.psd1       # Module manifest - defines exports and dependencies
├── BPlusDBRefresh.psm1       # Module root - auto-loads Public/Private functions
├── Public/                    # Exported functions (3 total)
│   ├── Invoke-BPlusDBRefresh.ps1   # Main entry point - orchestrates workflow
│   ├── Get-BPlusConfiguration.ps1  # Config parsing with INI→JSON migration
│   └── Convert-IniToJson.ps1       # Migration utility (v2.1.0 feature)
├── Private/                   # Internal helpers (15 functions)
│   ├── Backup-DatabaseConnectionInfo.ps1
│   ├── Restore-BPlusDatabase.ps1
│   ├── Set-DatabasePermissions.ps1
│   ├── Send-CompletionNotification.ps1
│   └── ... (11 more)
└── Resources/                 # SQL queries and email templates (NOT in code)
    ├── SQL/                   # *.sql files loaded via Get-Content
    │   ├── Set-IfasPermissions.sql
    │   ├── Set-SyscatPermissions.sql
    │   ├── Set-AspnetPermissions.sql
    │   └── Disable-Workflows.sql
    └── Templates/
        └── CompletionEmail.html   # HTML email template
```

**Critical Architecture Details:**

1. **Module Loading (BPlusDBRefresh.psm1):**
   - Dot-sources all `Private/*.ps1` first, then `Public/*.ps1`
   - Sets `$script:ModuleRoot` and `$script:ResourcesPath` for use across functions
   - `Export-ModuleMember` exports only Public function basenames

2. **SQL Queries Are Files, Not Strings:**
   - Private functions load SQL from `Resources/SQL/*.sql` via `Get-Content -Raw`
   - Example: `Set-DatabasePermissions.ps1` reads `Set-IfasPermissions.sql`
   - When modifying database operations, edit the SQL files, not the PowerShell code

3. **Configuration Migration Pattern:**
   - `Get-BPlusConfiguration` detects INI vs JSON by file extension
   - If INI detected: prompts user to auto-migrate via `Invoke-IniMigration`
   - `-SkipMigrationPrompt` switch for CI/automation scenarios
   - JSON is the primary format (v2.1.0+), INI is legacy (v1.x)

## Development Commands

### Module Operations
```powershell
# Import the module (required before testing functions)
Import-Module ./src/BPlusDBRefresh/BPlusDBRefresh.psd1 -Force

# Run the main workflow (requires SQL Server environment)
Invoke-BPlusDBRefresh -BPEnvironment TEST1 `
  -ifasFilePath "\\backup\ifas.bak" `
  -syscatFilePath "\\backup\syscat.bak"

# Test config parsing (works without SQL Server)
$config = Get-BPlusConfiguration -Path ./Tests/Fixtures/TestConfig.json -Environment TEST1

# Migrate legacy INI to JSON
Convert-IniToJson -IniPath ./bpcBPlusDBRefresh.ini -JsonPath ./bpcBPlusDBRefresh.json
```

### Testing
```powershell
# Run all tests (Unit + Integration)
Invoke-Pester ./Tests

# Run only unit tests (isolated functions, no mocks)
Invoke-Pester ./Tests/Unit

# Run only integration tests (workflow with mocked dbatools/PSLogging)
Invoke-Pester ./Tests/Integration

# Run specific test file
Invoke-Pester ./Tests/Unit/Get-BPlusConfiguration.Tests.ps1

# Run with coverage
Invoke-Pester ./Tests -CodeCoverage ./src/**/*.ps1
```

### Code Quality
```powershell
# PSScriptAnalyzer (enforces OTBS, 4-space indent, no aliases)
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1

# Fix auto-fixable issues
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1 -Fix
```

## Workflow Architecture

**13-Step Database Refresh Process** (orchestrated by `Invoke-BPlusDBRefresh`):

1. **Import-RequiredModule** - Loads PSLogging and dbatools
2. **Get-BPlusConfiguration** - Parses JSON config for target environment
3. **Show-ConfigurationReview** - User confirmation prompt
4. **Stop-BPlusServices** - Stops IPC daemon on all environment servers
5. **Backup-DatabaseConnectionInfo** - Captures current DB connection config
6. **Restore-BPlusDatabase** - Restores aspnet/syscat/ifas from .bak files
7. **Restore connection data** - Re-applies saved connection config
8. **Set-DatabasePermissions** - Runs SQL scripts from Resources/SQL/
9. **Disable-BPlusWorkflows** - Disables production workflows in test
10. **Update NUUPAUSY** - Sets test environment indicator text
11. **Update dashboard URL** - Points to test dashboard
12. **(Optional) Restore dashboard files** - If `-RestoreDashboards` specified
13. **Reboot servers + Send-CompletionNotification** - Restart environment, email stakeholders

**Key Dependencies Between Steps:**
- Step 5 MUST complete before Step 6 (connection data backup before restore)
- Step 6 MUST complete before Step 7 (restore DB before re-applying config)
- Step 8 MUST complete before Step 9 (permissions before disabling workflows)

## Testing Patterns

**Unit Tests** (`Tests/Unit/`):
- Test individual Public/Private functions in isolation
- Dot-source the specific function file, not the full module
- Use `BeforeAll { . $PSScriptRoot/../../src/BPlusDBRefresh/Private/FunctionName.ps1 }`
- Mock external cmdlets (dbatools, Test-Path, Get-Content) to avoid dependencies

**Integration Tests** (`Tests/Integration/`):
- Test `Invoke-BPlusDBRefresh` with mocked SQL Server and service operations
- Dot-source all Public + Private functions to test full workflow
- Mock dbatools cmdlets (`Restore-DbaDatabase`, `Invoke-DbaQuery`, etc.)
- Use `Tests/Fixtures/TestConfig.json` as sample configuration

**Test Fixtures** (`Tests/Fixtures/`):
- `TestConfig.json` - Valid JSON configuration for unit tests
- `TestConfig.ini` - Legacy INI for migration testing

## Configuration Structure

**JSON Format** (v2.1.0+):
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

**Key Configuration Sections:**
- **environments** - Container for all environment-specific configurations (e.g., TEST1, PROD)
- **environments.\<ENV\>.sqlServer** - SQL Server instance for this environment
- **environments.\<ENV\>.database, syscat, aspnet** - Database names for this environment
- **environments.\<ENV\>.filepathData, filepathLog, filepathImages** - SQL Server file paths for database restore
- **environments.\<ENV\>.fileDriveData, fileDriveSyscat, fileDriveAspnet** - Logical file name mappings
- **environments.\<ENV\>.iusrSource/Destination, adminSource/Destination, dboSource/Destination** - Account mappings (prod→test)
- **environments.\<ENV\>.managerCodes** - User accounts to keep active in test environment
- **environments.\<ENV\>.testingModeCodes** - Additional accounts to enable with `-testingMode` switch
- **smtp** - Email notification settings (applies to all environments, uses MailKit)

## Common Modification Patterns

### Adding a New Database Operation

1. Create SQL file in `src/BPlusDBRefresh/Resources/SQL/NewOperation.sql`
2. Add private function in `src/BPlusDBRefresh/Private/Invoke-NewOperation.ps1`
3. Load SQL via:
   ```powershell
   $sqlPath = Join-Path -Path $script:ResourcesPath -ChildPath 'SQL\NewOperation.sql'
   $sql = Get-Content -Path $sqlPath -Raw
   Invoke-DbaQuery -SqlInstance $config.DatabaseServer -Database $config.Database -Query $sql
   ```
4. Add function call to `Invoke-BPlusDBRefresh` workflow
5. Add unit test in `Tests/Unit/Invoke-NewOperation.Tests.ps1`

### Adding a New Configuration Field

1. Add to sample configs: `bpcBPlusDBRefresh-sample.json` and `bpcBPlusDBRefresh-sample.ini`
2. Update `Get-BPlusConfiguration.ps1` to parse the new field
3. Update `Convert-IniToJson.ps1` if field exists in legacy INI format
4. Add validation in `Get-BPlusConfiguration` if field is mandatory
5. Update `Tests/Fixtures/TestConfig.json` for tests
6. Add test cases in `Tests/Unit/Get-BPlusConfiguration.Tests.ps1`

### Modifying Email Notifications

1. Edit HTML template: `src/BPlusDBRefresh/Resources/Templates/CompletionEmail.html`
2. Template uses placeholders: `{{EnvironmentName}}`, `{{CompletionTime}}`, `{{DatabaseServer}}`
3. Placeholder replacement happens in `Send-CompletionNotification.ps1` via `-replace` operator
4. Uses MailKit for SMTP (not deprecated `Send-MailMessage`)

## Module Versioning

**Version History:**
- **v2.1.0** - JSON configuration (INI deprecated), removed PsIni dependency
- **v2.0.0** - Refactored to module structure, added Pester tests, externalized SQL/templates
- **v1.x** - Original monolithic script (`hpsBPlusDBRestore.ps1`) with INI config

**When bumping version:**
1. Update `ModuleVersion` in `src/BPlusDBRefresh/BPlusDBRefresh.psd1`
2. Add release notes to `ReleaseNotes` section in manifest
3. Update MAJOR for breaking changes, MINOR for features, PATCH for fixes

## Dependencies

**Required Modules** (listed in module manifest):
- **PSLogging** - Structured logging framework (Write-LogMessage wrapper)
- **dbatools** - SQL Server database operations (Restore-DbaDatabase, Invoke-DbaQuery)

**Optional Runtime Dependencies:**
- **MailKit/MimeKit** - Email notifications (auto-installed by Install-MailKitDependency if missing)

**Development Dependencies:**
- **Pester** - Testing framework (v5.x)
- **PSScriptAnalyzer** - Code quality and style enforcement
