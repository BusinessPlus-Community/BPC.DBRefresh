# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

BPlusDBRefresh is a PowerShell module (v2.1.0) that automates BusinessPlus test environment database refresh operations. It follows the PoshCode PowerShell Practice and Style Guide with a modular architecture, externalized SQL/templates, and comprehensive Pester tests.

## Development Commands

```powershell
# Import the module
Import-Module ./src/BPlusDBRefresh/BPlusDBRefresh.psd1 -Force

# Run all tests
Invoke-Pester ./Tests

# Run unit tests only
Invoke-Pester ./Tests/Unit

# Run a single test file
Invoke-Pester ./Tests/Unit/Get-BPlusConfiguration.Tests.ps1

# Run integration tests (workflow with mocked dbatools/PSLogging)
Invoke-Pester ./Tests/Integration

# PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1

# Auto-fix
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1 -Fix
```

## Module Architecture

**Key Principle:** Code lives in functions, data lives in Resources.

```
src/BPlusDBRefresh/
├── BPlusDBRefresh.psd1       # Module manifest - exports, dependencies, version
├── BPlusDBRefresh.psm1       # Module root - dot-sources Private/ then Public/
├── Public/                    # Exported functions (3)
│   ├── Invoke-BPlusDBRefresh.ps1   # Main entry point - 13-step workflow
│   ├── Get-BPlusConfiguration.ps1  # Config parsing with INI→JSON migration
│   └── Convert-IniToJson.ps1       # Migration utility
├── Private/                   # Internal helpers (13 functions in 13 files)
└── Resources/                 # SQL queries and email templates (NOT in code)
    ├── SQL/                   # *.sql files with @parameter placeholders
    └── Templates/             # HTML templates with {{Token}} placeholders
```

### Module Loading

`BPlusDBRefresh.psm1` sets two module-scope variables used throughout:
- `$script:ModuleRoot` - Module directory path
- `$script:ResourcesPath` - Path to `Resources/` subdirectory

It dot-sources all `Private/*.ps1` first, then `Public/*.ps1`, and exports only Public function basenames.

### Resource Loading Pattern

SQL and templates are loaded through helper functions in `Private/Get-ScriptPath.ps1` (which contains 4 functions despite the filename):

- **`Get-SqlResourceContent -FileName 'Set-IfasPermissions.sql' -Parameters @{...}`** - Loads SQL from `Resources/SQL/`, replaces `@ParameterName` placeholders with values
- **`Get-TemplateContent -FileName 'CompletionEmail.html' -Tokens @{...}`** - Loads templates from `Resources/Templates/`, replaces `{{TokenName}}` placeholders
- **`Get-ResourcePath -SubPath 'SQL'`** - Resolves paths within Resources/
- **`Get-ScriptPath`** - Returns module root directory

When modifying database operations, edit the `.sql` files in `Resources/SQL/`, not the PowerShell code. Parameters use `@Name` syntax and are substituted at runtime.

### Configuration Migration

- `Get-BPlusConfiguration` detects INI vs JSON by file extension
- If INI detected: prompts user to auto-migrate via `Invoke-IniMigration` (private function)
- `-SkipMigrationPrompt` switch for CI/automation
- JSON Schema validation: `bpcBPlusDBRefresh.schema.json` (Draft 2020-12)

### Notable Implementation Details

- `Build-FileMapping` is a nested function inside `Restore-BPlusDatabase.ps1` (not its own file)
- Email uses MailKit/MimeKit (not deprecated `Send-MailMessage`), auto-installed by `Install-MailKitDependency`
- `Write-LogMessage` wraps PSLogging's `Write-LogInfo`/`Write-LogError`

## Workflow Architecture

**13-Step Database Refresh** (orchestrated by `Invoke-BPlusDBRefresh`):

1. Import-RequiredModule → 2. Get-BPlusConfiguration → 3. Show-ConfigurationReview → 4. Stop-BPlusServices → 5. Backup-DatabaseConnectionInfo → 6. Restore-BPlusDatabase → 7. Restore connection data → 8. Set-DatabasePermissions → 9. Disable-BPlusWorkflows → 10. Update NUUPAUSY → 11. Update dashboard URL → 12. (Optional) Restore dashboards → 13. Reboot + Send-CompletionNotification

**Critical ordering:** Step 5 before 6 (backup before restore), Step 6 before 7 (restore before re-apply), Step 8 before 9 (permissions before workflows).

## Testing Patterns

**Unit Tests** (`Tests/Unit/`) - Dot-source individual function files:
```powershell
BeforeAll { . $PSScriptRoot/../../src/BPlusDBRefresh/Private/FunctionName.ps1 }
```
Mock external cmdlets (dbatools, Test-Path, Get-Content).

**Integration Tests** (`Tests/Integration/`) - Dot-source all Public + Private functions, mock dbatools cmdlets.

**Fixtures** in `Tests/Fixtures/`: `TestConfig.json` and `TestConfig.ini`.

## Configuration

JSON config structure with environments and SMTP sections. See `bpcBPlusDBRefresh-sample.json` for the full template and `bpcBPlusDBRefresh.schema.json` for validation rules.

Config files use the `bpcBPlusDBRefresh` prefix (renamed from `hpsBPlusDBRestore` in v2.1.0).

## Common Modification Patterns

### Adding a New Database Operation

1. Create SQL file in `Resources/SQL/NewOperation.sql` (use `@ParamName` for parameters)
2. Add private function in `Private/Invoke-NewOperation.ps1` using `Get-SqlResourceContent`
3. Add function call to `Invoke-BPlusDBRefresh` workflow
4. Add unit test in `Tests/Unit/Invoke-NewOperation.Tests.ps1`

### Adding a New Configuration Field

1. Add to `bpcBPlusDBRefresh-sample.json` and `bpcBPlusDBRefresh-sample.ini`
2. Add to schema: `bpcBPlusDBRefresh.schema.json`
3. Update `Get-BPlusConfiguration.ps1` to parse the field
4. Update `Convert-IniToJson.ps1` if field exists in legacy INI
5. Update `Tests/Fixtures/TestConfig.json` and add test cases

### Modifying Email Notifications

1. Edit `Resources/Templates/CompletionEmail.html` (uses `{{TokenName}}` placeholders)
2. Placeholder replacement happens via `Get-TemplateContent` in `Send-CompletionNotification.ps1`

## Code Style

- **PSScriptAnalyzer:** `PSScriptAnalyzerSettings.psd1` enforces OTBS brace style, 4-space indent, no aliases, approved verbs
- **Exception:** `PSAvoidUsingWriteHost` is excluded (Write-Host allowed for interactive display)
- **Comment-based help** required for all exported functions (SYNOPSIS, DESCRIPTION, PARAMETER, EXAMPLE)

## Dependencies

**Required:** PSLogging, dbatools (listed in module manifest)
**Optional:** MailKit/MimeKit (auto-installed at runtime if missing)
**Dev:** Pester v5.x, PSScriptAnalyzer

## Version Bumping

1. Update `ModuleVersion` in `src/BPlusDBRefresh/BPlusDBRefresh.psd1`
2. Add release notes to `ReleaseNotes` in the manifest's PrivateData.PSData
3. MAJOR for breaking changes, MINOR for features, PATCH for fixes
