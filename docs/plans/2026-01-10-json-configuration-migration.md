# JSON Configuration Migration Plan

Created: 2026-01-10
Status: VERIFIED
Approved: Yes

> **Status Lifecycle:** PENDING → COMPLETE → VERIFIED
> - PENDING: Initial state, awaiting implementation
> - COMPLETE: All tasks implemented (set by /implement)
> - VERIFIED: Rules supervisor passed (set automatically)
>
> **Approval Gate:** Implementation CANNOT proceed until `Approved: Yes`

## Summary

**Goal:** Migrate BPlusDBRefresh configuration from INI format (PsIni module) to JSON format for cross-platform compatibility (Windows, Linux, macOS).

**Architecture:** Replace PsIni dependency with native PowerShell `ConvertFrom-Json`. The JSON structure will mirror the existing INI section/key hierarchy but in a more structured, environment-keyed format. A migration script will convert existing INI files.

**Tech Stack:**
- PowerShell 5.1+ native JSON cmdlets (ConvertFrom-Json, ConvertTo-Json)
- No external module dependencies for configuration

## Scope

### In Scope
- Create JSON configuration schema matching INI structure
- Update `Get-BPlusConfiguration` to parse JSON instead of INI
- Remove PsIni from RequiredModules in module manifest
- Create `Convert-IniToJson` migration utility
- Create sample JSON configuration file
- Update tests for JSON parsing
- Update documentation

### Out of Scope
- Changing the configuration values or adding new settings
- Modifying business logic in other functions
- Changing the output structure of Get-BPlusConfiguration (maintains same PSCustomObject)

## Prerequisites
- Existing module structure in `src/BPlusDBRefresh/`
- PowerShell 5.1+ with native JSON support

## Context for Implementer

### Current INI Structure
The INI file uses sections like `[sqlServer]`, `[database]`, etc. with environment-specific keys:
```ini
[sqlServer]
TEST1=server.domain.lcl

[SMTP]
host=smtp.domain.lcl
port=25
```

### Target JSON Structure
```json
{
  "environments": {
    "TEST1": {
      "sqlServer": "server.domain.lcl",
      "database": "bplus_test1",
      ...
    }
  },
  "smtp": {
    "host": "smtp.domain.lcl",
    "port": 25
  }
}
```

### Key Difference
- INI: Section per setting type, environment as key within section
- JSON: Environment as top-level key, settings nested within

## Feature Inventory

### Files Being Modified

| File | Changes | Mapped to Task |
|------|---------|----------------|
| `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1` | Replace INI parsing with JSON | Task 2 |
| `src/BPlusDBRefresh/BPlusDBRefresh.psd1` | Remove PsIni from RequiredModules | Task 3 |
| `Tests/Unit/Get-BPlusConfiguration.Tests.ps1` | Update tests for JSON | Task 5 |
| `Tests/Fixtures/TestConfig.ini` | Replace with TestConfig.json | Task 5 |

### New Files

| File | Purpose | Mapped to Task |
|------|---------|----------------|
| `hpsBPlusDBRestore-sample.json` | Sample JSON configuration | Task 1 |
| `src/BPlusDBRefresh/Public/Convert-IniToJson.ps1` | Migration utility | Task 4 |

## Progress Tracking

**MANDATORY: Update this checklist as tasks complete.**

- [x] Task 1: Create JSON configuration schema and sample file
- [x] Task 2: Update Get-BPlusConfiguration for JSON parsing
- [x] Task 3: Update module manifest (remove PsIni dependency)
- [x] Task 4: Create Convert-IniToJson migration utility
- [x] Task 5: Update tests for JSON configuration

**Total Tasks:** 5 | **Completed:** 5 | **Remaining:** 0

## Implementation Tasks

### Task 1: Create JSON Configuration Schema and Sample File

**Objective:** Create the JSON configuration schema that mirrors the existing INI structure.

**Files:**
- Create: `hpsBPlusDBRestore-sample.json`

**Implementation Steps:**
1. Create JSON structure with `environments` object containing environment-specific settings
2. Create `smtp` object for shared SMTP settings
3. Include all settings from the INI sample with proper JSON types (strings, numbers, arrays)
4. Add JSON schema comments as `_comment` fields for documentation

**JSON Schema:**
```json
{
  "$schema": "Configuration for BPlusDBRefresh",
  "environments": {
    "TEST1": {
      "sqlServer": "TBPLUSSQL01.district.lcl",
      "database": "businessplus",
      "syscat": "syscat_db",
      "aspnet": "aspnet_db",
      "filepathData": "D:\\MSSQL\\Data",
      "filepathLog": "L:\\MSSQL\\Log",
      "filepathImages": "I:\\MSSQL\\Images",
      "fileDriveData": ["ifas:Data:ifas.MDF", "ifas_log:Log:ifas.LDF"],
      "fileDriveSyscat": ["syscat:Data:syscat.MDF", "syscat_log:Log:syscat.LDF"],
      "fileDriveAspnet": ["aspnet:Data:aspnet.MDF"],
      "environmentServers": ["web1.domain.lcl", "app1.domain.lcl"],
      "ipcDaemon": "ipc_ifas",
      "nuupausy": "TEST Environment",
      "iusrSource": "PROD\\IUSR_BPLUS",
      "iusrDestination": "TEST\\IUSR_BPLUS",
      "adminSource": "PROD\\admin",
      "adminDestination": "TEST\\admin",
      "dboSource": "PROD\\dbo",
      "dboDestination": "TEST\\dbo",
      "dummyEmail": "noreply@district.org",
      "managerCodes": ["DBA"],
      "testingModeCodes": ["DBA", "QA"],
      "dashboardUrl": "https://web1.domain.lcl/",
      "dashboardFiles": "\\\\src\\dash:\\\\dst\\dash"
    }
  },
  "smtp": {
    "host": "smtp.district.org",
    "port": 25,
    "replyToEmail": "noreply@district.org",
    "notificationEmail": "support@district.org",
    "mailMessageAddress": "District Name, 123 Main St"
  }
}
```

**Definition of Done:**
- [ ] JSON file is valid (parseable by ConvertFrom-Json)
- [ ] All INI settings represented in JSON
- [ ] Array types used for comma-separated values

---

### Task 2: Update Get-BPlusConfiguration for JSON Parsing

**Objective:** Replace PsIni's Get-IniContent with native ConvertFrom-Json.

**Files:**
- Modify: `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1`

**Implementation Steps:**
1. Change parameter help to reference JSON instead of INI
2. Replace `Get-IniContent` with `Get-Content | ConvertFrom-Json`
3. Update helper functions to access JSON structure:
   - `$getValue`: Access `$jsonContent.environments.$Environment.$Key`
   - `$getList`: Arrays are native in JSON, no split needed
   - SMTP settings: Access `$jsonContent.smtp.$Key`
4. Handle both old-style (string arrays in JSON) and new-style (native arrays)
5. Maintain same output PSCustomObject structure

**Key Changes:**
```powershell
# OLD (INI)
$iniContent = Get-IniContent -FilePath $Path
$value = $iniContent[$Section][$Key]

# NEW (JSON)
$jsonContent = Get-Content -Path $Path -Raw | ConvertFrom-Json
$envConfig = $jsonContent.environments.$Environment
$value = $envConfig.$Key
```

**Definition of Done:**
- [ ] Function parses JSON configuration correctly
- [ ] Output PSCustomObject structure unchanged
- [ ] Existing callers work without modification
- [ ] Error handling for missing/invalid JSON

---

### Task 3: Update Module Manifest

**Objective:** Remove PsIni from RequiredModules since it's no longer needed.

**Files:**
- Modify: `src/BPlusDBRefresh/BPlusDBRefresh.psd1`

**Implementation Steps:**
1. Remove 'PsIni' from RequiredModules array
2. Update module description to mention JSON configuration
3. Update ReleaseNotes

**Definition of Done:**
- [ ] PsIni removed from RequiredModules
- [ ] Module manifest still valid (Test-ModuleManifest)
- [ ] Module loads without PsIni installed

---

### Task 4: Create Convert-IniToJson Migration Utility

**Objective:** Create a utility to convert existing INI files to JSON format.

**Files:**
- Create: `src/BPlusDBRefresh/Public/Convert-IniToJson.ps1`

**Implementation Steps:**
1. Create function with CmdletBinding and parameter for INI path
2. Parse INI file manually (regex or simple line parsing)
3. Build JSON structure matching Task 1 schema
4. Output JSON string or write to file
5. Add to FunctionsToExport in manifest

**Function Signature:**
```powershell
function Convert-IniToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$IniPath,

        [Parameter()]
        [string]$OutputPath
    )
}
```

**Definition of Done:**
- [ ] Converts sample INI to valid JSON
- [ ] Preserves all configuration values
- [ ] Handles comma-separated values as arrays
- [ ] Outputs formatted JSON

---

### Task 5: Update Tests for JSON Configuration

**Objective:** Update tests to use JSON configuration instead of INI.

**Files:**
- Modify: `Tests/Unit/Get-BPlusConfiguration.Tests.ps1`
- Create: `Tests/Fixtures/TestConfig.json`
- Delete: `Tests/Fixtures/TestConfig.ini`

**Implementation Steps:**
1. Create TestConfig.json fixture with test data
2. Update BeforeAll to create JSON test files instead of INI
3. Remove PsIni-related skip conditions
4. Update mock to return JSON-parsed objects
5. Verify all tests pass

**Definition of Done:**
- [ ] All Get-BPlusConfiguration tests pass
- [ ] No PsIni dependency in tests
- [ ] Tests run on Linux/macOS

---

## Testing Strategy

### Unit Tests
- Test JSON parsing with valid configuration
- Test error handling for malformed JSON
- Test missing required fields
- Test default value handling

### Integration Tests
- Test Convert-IniToJson produces valid configuration
- Test module loads without PsIni

### Manual Verification
```powershell
# Test on Linux/macOS
pwsh -Command "Import-Module ./src/BPlusDBRefresh; Get-BPlusConfiguration -Path ./sample.json -Environment TEST1"
```

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing users with INI files | Medium | High | Provide Convert-IniToJson utility and documentation |
| JSON parsing errors | Low | Medium | Comprehensive error messages |
| Path escaping in JSON | Low | Low | Document double-backslash requirement |

## Open Questions
- None - JSON is the standard cross-platform approach for PowerShell configuration
