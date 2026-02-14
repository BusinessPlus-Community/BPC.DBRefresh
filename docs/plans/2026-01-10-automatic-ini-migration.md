# Automatic INI-to-JSON Migration Feature

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

**Goal:** Provide seamless automatic migration from INI to JSON configuration for existing BPlusDBRefresh users.

**Architecture:** Create a private helper function `Invoke-IniMigration` that handles all migration logic, called by `Get-BPlusConfiguration` when an INI file is detected. Uses interactive prompts for user confirmation, creates backups, and loads the new JSON configuration transparently.

**Tech Stack:**
- PowerShell native `$Host.UI.PromptForChoice()` for interactive prompts
- Existing `Convert-IniToJson` function for actual conversion
- File system operations for backup/rename

## Scope

### In Scope
- Auto-detection of INI files by extension when calling `Get-BPlusConfiguration`
- Interactive prompt asking user to confirm migration
- Creating `.ini.bak` backup before migration
- Converting INI to JSON using existing `Convert-IniToJson` function
- Renaming original INI to `.ini.bak` after successful conversion
- Loading newly created JSON configuration seamlessly
- Optional `-SkipMigrationPrompt` switch for automation/CI scenarios
- Unit tests for migration logic
- Integration tests for end-to-end migration flow

### Out of Scope
- Changing the JSON schema or configuration structure
- Auto-detecting INI by content (only by extension)
- Migration of partial/invalid INI files (will fail with clear error)
- Rollback functionality (backup is preserved for manual rollback)

## Prerequisites
- Existing `Convert-IniToJson` function (already implemented)
- Existing JSON configuration loading (already implemented)
- Test fixtures with INI files

## Context for Implementer

### File Detection Logic
INI files are detected by the `.ini` extension (case-insensitive). When detected:
1. Display migration prompt with file paths
2. Wait for user confirmation
3. On confirm: backup → convert → rename → load JSON
4. On decline: throw error explaining JSON is required

### PowerShell Interactive Prompt Pattern
```powershell
$title = "Configuration Migration Required"
$message = "The configuration file uses the legacy INI format..."
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Migrate to JSON"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancel and exit"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$result = $Host.UI.PromptForChoice($title, $message, $options, 0)
```

### Existing Convert-IniToJson Interface
```powershell
Convert-IniToJson -IniPath 'config.ini' -OutputPath 'config.json' [-Environments @('ENV1', 'ENV2')]
```
- Auto-detects environments from sqlServer section if not specified
- Returns success message when OutputPath is provided

### Module Structure
- Public functions: `src/BPlusDBRefresh/Public/`
- Private functions: `src/BPlusDBRefresh/Private/`
- Private functions are dot-sourced by the module but not exported

## Feature Inventory

### Files Being Modified

| File | Changes | Mapped to Task |
|------|---------|----------------|
| `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1` | Add INI detection and migration trigger | Task 2 |
| `Tests/Unit/Get-BPlusConfiguration.Tests.ps1` | Add migration-related tests | Task 4 |

### New Files

| File | Purpose | Mapped to Task |
|------|---------|----------------|
| `src/BPlusDBRefresh/Private/Invoke-IniMigration.ps1` | Migration helper function | Task 1 |
| `Tests/Fixtures/TestConfig.ini` | INI fixture for testing migration | Task 3 |
| `Tests/Unit/Invoke-IniMigration.Tests.ps1` | Unit tests for migration function | Task 4 |

## Progress Tracking

**MANDATORY: Update this checklist as tasks complete.**

- [x] Task 1: Create Invoke-IniMigration private function
- [x] Task 2: Update Get-BPlusConfiguration for INI detection
- [x] Task 3: Create INI test fixture
- [x] Task 4: Add unit tests for migration
- [x] Task 5: Add integration tests for end-to-end flow

**Total Tasks:** 5 | **Completed:** 5 | **Remaining:** 0

## Implementation Tasks

### Task 1: Create Invoke-IniMigration Private Function

**Objective:** Create the private helper function that handles all migration logic.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Invoke-IniMigration.ps1`

**Implementation Steps:**
1. Create function with CmdletBinding
2. Parameters: `$IniPath` (mandatory), `$SkipPrompt` (switch)
3. Implement interactive prompt using `$Host.UI.PromptForChoice()`
4. Create backup by copying INI to `.ini.bak`
5. Call `Convert-IniToJson` to create JSON file (same location, `.json` extension)
6. Verify JSON was created successfully
7. Rename original INI to `.ini.bak` (overwrite existing backup copy)
8. Return path to new JSON file

**Function Signature:**
```powershell
function Invoke-IniMigration {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$IniPath,

        [Parameter()]
        [switch]$SkipPrompt
    )
}
```

**Definition of Done:**
- [ ] Function creates backup before any changes
- [ ] Function prompts user unless SkipPrompt is set
- [ ] Function returns path to new JSON file on success
- [ ] Function throws descriptive error if user declines
- [ ] Function throws descriptive error if conversion fails

---

### Task 2: Update Get-BPlusConfiguration for INI Detection

**Objective:** Modify Get-BPlusConfiguration to detect INI files and trigger migration.

**Files:**
- Modify: `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1`

**Implementation Steps:**
1. Add optional `-SkipMigrationPrompt` switch parameter
2. At start of `process` block, check if Path ends with `.ini` (case-insensitive)
3. If INI detected, dot-source and call `Invoke-IniMigration`
4. Update `$Path` variable to point to new JSON file
5. Continue with existing JSON loading logic

**Key Changes:**
```powershell
# Add parameter
[Parameter()]
[switch]$SkipMigrationPrompt

# In process block, before JSON loading
if ($Path -match '\.ini$') {
    Write-Verbose "INI file detected, initiating migration..."
    . "$PSScriptRoot\..\Private\Invoke-IniMigration.ps1"
    $Path = Invoke-IniMigration -IniPath $Path -SkipPrompt:$SkipMigrationPrompt
    Write-Verbose "Migration complete, loading JSON from: $Path"
}
```

**Definition of Done:**
- [ ] INI files trigger migration automatically
- [ ] JSON files load directly (no change to current behavior)
- [ ] SkipMigrationPrompt switch works correctly
- [ ] Help documentation updated

---

### Task 3: Create INI Test Fixture

**Objective:** Create an INI configuration file fixture for testing migration.

**Files:**
- Create: `Tests/Fixtures/TestConfig.ini`

**Implementation Steps:**
1. Create INI file matching the structure expected by Convert-IniToJson
2. Include TEST1 environment (matching TestConfig.json)
3. Include SMTP section
4. Include all required fields for a valid configuration

**Content Structure:**
```ini
[sqlServer]
TEST1=TESTDBSRV01.test.lcl

[database]
TEST1=bplus_test1

[syscat]
TEST1=syscat_test1

# ... all other required sections
```

**Definition of Done:**
- [ ] INI file is valid and parseable
- [ ] INI file contains TEST1 environment
- [ ] INI file can be converted to JSON by Convert-IniToJson
- [ ] Converted JSON matches TestConfig.json structure

---

### Task 4: Add Unit Tests for Migration

**Objective:** Create comprehensive unit tests for the migration feature.

**Files:**
- Create: `Tests/Unit/Invoke-IniMigration.Tests.ps1`
- Modify: `Tests/Unit/Get-BPlusConfiguration.Tests.ps1`

**Implementation Steps:**

**Invoke-IniMigration.Tests.ps1:**
1. Test backup creation (verify .ini.bak exists)
2. Test JSON output (verify .json created)
3. Test original INI renamed to .bak
4. Test SkipPrompt switch bypasses prompt
5. Test error handling for invalid INI
6. Test error handling when user declines (mock $Host.UI)

**Get-BPlusConfiguration.Tests.ps1 additions:**
1. Add context "INI Migration"
2. Test that INI file triggers migration
3. Test that JSON file does not trigger migration
4. Test SkipMigrationPrompt parameter exists
5. Test end-to-end: INI input → JSON configuration output

**Test Structure:**
```powershell
Describe 'Invoke-IniMigration' {
    Context 'Backup Creation' { }
    Context 'JSON Conversion' { }
    Context 'User Prompt' { }
    Context 'Error Handling' { }
}
```

**Definition of Done:**
- [ ] All new tests pass
- [ ] Tests cover backup, conversion, rename, prompt logic
- [ ] Tests use TestDrive for isolation
- [ ] Mocking used for interactive prompt tests

---

### Task 5: Add Integration Tests for End-to-End Flow

**Objective:** Test the complete migration flow from INI to successful configuration load.

**Files:**
- Modify: `Tests/Integration/Invoke-BPlusDBRefresh.Tests.ps1`

**Implementation Steps:**
1. Add context "Configuration Migration"
2. Test: INI file → migration → valid configuration object
3. Test: Verify backup file preserved
4. Test: Verify original INI renamed
5. Test: Verify configuration values match expected

**Definition of Done:**
- [ ] Integration test covers full migration flow
- [ ] Test verifies configuration object is valid after migration
- [ ] Test verifies file system state after migration

---

## Testing Strategy

### Unit Tests
- `Invoke-IniMigration`: Backup creation, JSON conversion, file rename, prompt handling
- `Get-BPlusConfiguration`: INI detection, SkipMigrationPrompt switch

### Integration Tests
- End-to-end: INI input → backup created → JSON created → INI renamed → configuration loaded

### Manual Verification
```powershell
# Test interactive migration
Get-BPlusConfiguration -Path './test.ini' -Environment 'TEST1'
# Should prompt, then return valid config

# Test skip prompt
Get-BPlusConfiguration -Path './test.ini' -Environment 'TEST1' -SkipMigrationPrompt
# Should migrate silently

# Verify files after migration
Test-Path './test.ini'      # Should be False
Test-Path './test.ini.bak'  # Should be True
Test-Path './test.json'     # Should be True
```

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User declines migration, loses work | Low | Low | Clear error message explains JSON is required |
| Conversion fails partway through | Low | Medium | Backup created BEFORE any conversion |
| Existing .ini.bak overwritten | Low | Low | This is expected behavior per user choice |
| Non-interactive environment | Medium | Medium | SkipMigrationPrompt switch for automation |

## Open Questions
- None - all requirements confirmed by user interview
