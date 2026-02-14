# BPlusDBRefresh PowerShell Module Refactoring Plan

Created: 2026-01-10
Status: VERIFIED
Approved: Yes

> **Status Lifecycle:** PENDING → COMPLETE → VERIFIED
> - PENDING: Initial state, awaiting implementation
> - COMPLETE: All tasks implemented (set by /implement)
> - VERIFIED: Rules supervisor passed (set automatically)
>
> **Approval Gate:** Implementation CANNOT proceed until `Approved: Yes`
> - Claude will ask for your approval after presenting the plan
> - You can request changes before approving
> - Claude updates this field automatically when you approve

## Summary

**Goal:** Refactor the `hpsBPlusDBRestore.ps1` script into a proper PowerShell module (`BPlusDBRefresh`) following the PoshCode/PowerShellPracticeAndStyle guide, with comprehensive error handling, externalized SQL/HTML templates, and Pester tests.

**Architecture:** The monolithic 1200-line script will be decomposed into a PowerShell module with:
- A module manifest (`.psd1`) defining metadata, dependencies, and exports
- Private functions in `Private/` for internal helper operations
- Public functions in `Public/` for the main cmdlets
- External resources in `Resources/` (SQL queries, HTML templates)
- Pester tests in `Tests/` mirroring the function structure

**Tech Stack:**
- PowerShell 5.1+ (maintaining `#requires -version 3` compatibility where possible)
- PSLogging, dbatools, PsIni modules (existing dependencies)
- MailKit/MimeKit (.NET libraries for email)
- Pester 5.x for testing

## Scope

### In Scope
- Convert script to proper PowerShell module structure
- Rename functions to use approved verbs (e.g., `Add-Module` → `Import-RequiredModule`)
- Apply One True Brace Style (OTBS) formatting throughout
- Add `[CmdletBinding()]` and proper parameter validation to all functions
- Add comment-based help to all public functions
- Externalize SQL queries to `.sql` files
- Externalize HTML email template to `.html` file
- Implement comprehensive Try/Catch error handling
- Remove `$ErrorActionPreference = 'SilentlyContinue'`
- Create Pester tests for key functions
- Update variable naming (remove Hungarian notation)
- Add module manifest with proper metadata
- Create PSScriptAnalyzer settings file

### Out of Scope
- Changing the business logic or workflow
- Adding new features beyond refactoring
- Migrating away from MailKit to Send-MailMessage
- Changing the INI file format or configuration structure
- Database schema changes

## Prerequisites
- PSLogging, dbatools, PsIni modules available
- **MailKit/MimeKit NuGet packages installed** (Send-MailMessage is deprecated per [DE0005](https://github.com/dotnet/platform-compat/blob/master/docs/DE0005.md))
- Pester 5.x for running tests
- PSScriptAnalyzer for validation

### MailKit Installation
The module will include a `Install-MailKitDependency` function to install MailKit via NuGet if not present:
```powershell
# Install MailKit via NuGet (one-time setup)
Install-Package -Name MailKit -ProviderName NuGet -Scope CurrentUser -Force
```
The module will verify MailKit availability at runtime and provide clear error messages if missing.

## Context for Implementer

### PowerShell Style Guide Key Rules (from PoshCode)
1. **Capitalization:** PascalCase for all public identifiers; lowercase for keywords
2. **Braces:** One True Brace Style (opening brace on same line)
3. **Indentation:** 4 spaces per level
4. **Line Length:** Max 115 characters
5. **Functions:** Always use `[CmdletBinding()]`; avoid `return` keyword
6. **Parameters:** Use full parameter names; use validation attributes
7. **Comments:** Document "why" not "what"; help inside functions at top
8. **Naming:** `Verb-Noun` format; approved verbs only; no Hungarian notation
9. **Error Handling:** Use `-ErrorAction Stop`; proper Try/Catch blocks

### Current Script Structure
The script follows this flow:
1. Parameter parsing → Module loading → INI parsing → Config display
2. Service stop → Capture existing DB config → Database restore
3. Environment config restore → SQL permissions → User/workflow disable
4. NUUPAUSY update → Dashboard restore → Server reboot → Email notification

### Approved PowerShell Verbs for This Module
- `Invoke-BPlusDBRefresh` (main entry point)
- `Import-RequiredModule` (was `Add-Module`)
- `Get-BPlusConfiguration` (INI parsing)
- `Stop-BPlusServices` / `Start-BPlusServices`
- `Backup-DatabaseConnectionInfo` / `Restore-DatabaseConnectionInfo`
- `Restore-BPlusDatabase`
- `Set-DatabasePermissions`
- `Disable-BPlusWorkflows`
- `Set-NuupausyText`
- `Copy-DashboardFiles`
- `Send-CompletionNotification`

## Feature Inventory

### Files Being Replaced

| Old File | Functions/Components | Mapped to Task |
|----------|---------------------|----------------|
| `hpsBPlusDBRestore.ps1` | Script parameters & initialization | Task 2 |
| `hpsBPlusDBRestore.ps1` | `Add-Module` function | Task 3 |
| `hpsBPlusDBRestore.ps1` | INI file parsing logic | Task 4 |
| `hpsBPlusDBRestore.ps1` | Configuration review display | Task 5 |
| `hpsBPlusDBRestore.ps1` | Service stop/start logic | Task 6 |
| `hpsBPlusDBRestore.ps1` | Database connection backup/restore | Task 7 |
| `hpsBPlusDBRestore.ps1` | Database restore operations | Task 8 |
| `hpsBPlusDBRestore.ps1` | SQL permission scripts | Task 9 |
| `hpsBPlusDBRestore.ps1` | Workflow/user disable logic | Task 10 |
| `hpsBPlusDBRestore.ps1` | NUUPAUSY & dashboard operations | Task 10 |
| `hpsBPlusDBRestore.ps1` | Server reboot logic | Task 11 |
| `hpsBPlusDBRestore.ps1` | HTML email building | Task 11 |
| `hpsBPlusDBRestore.ps1` | Email sending via MailKit | Task 11 |

### Feature Mapping Verification

- [x] All old files listed above
- [x] All functions/components identified
- [x] Every feature has a task number
- [x] No features accidentally omitted

## Progress Tracking

**MANDATORY: Update this checklist as tasks complete. Change `[ ]` to `[x]`.**

- [x] Task 1: Create module directory structure and manifest
- [x] Task 2: Create main entry point function (Invoke-BPlusDBRefresh)
- [x] Task 3: Create private helper functions (Import-RequiredModule, logging)
- [x] Task 4: Create Get-BPlusConfiguration function (INI parsing)
- [x] Task 5: Create Show-ConfigurationReview function
- [x] Task 6: Create service management functions (Stop/Start-BPlusServices)
- [x] Task 7: Create database connection functions
- [x] Task 8: Create Restore-BPlusDatabase function
- [x] Task 9: Externalize SQL queries and create Set-DatabasePermissions
- [x] Task 10: Create workflow/user management functions
- [x] Task 11: Create notification functions with externalized HTML template
- [x] Task 12: Create Pester tests and PSScriptAnalyzer configuration

**Total Tasks:** 12 | **Completed:** 12 | **Remaining:** 0

## Implementation Tasks

### Task 1: Create Module Directory Structure and Manifest

**Objective:** Set up the proper PowerShell module directory structure following best practices.

**Files:**
- Create: `src/BPlusDBRefresh/BPlusDBRefresh.psd1` (module manifest)
- Create: `src/BPlusDBRefresh/BPlusDBRefresh.psm1` (root module)
- Create: `src/BPlusDBRefresh/Public/.gitkeep`
- Create: `src/BPlusDBRefresh/Private/.gitkeep`
- Create: `src/BPlusDBRefresh/Resources/.gitkeep`
- Create: `PSScriptAnalyzerSettings.psd1`

**Implementation Steps:**
1. Create directory structure:
   ```
   src/
   └── BPlusDBRefresh/
       ├── BPlusDBRefresh.psd1
       ├── BPlusDBRefresh.psm1
       ├── Public/
       ├── Private/
       └── Resources/
   ```
2. Create module manifest with:
   - RootModule = 'BPlusDBRefresh.psm1'
   - ModuleVersion = '2.0.0'
   - RequiredModules = @('PSLogging', 'dbatools', 'PsIni')
   - FunctionsToExport = @('Invoke-BPlusDBRefresh', 'Get-BPlusConfiguration')
   - PowerShellVersion = '5.1'
3. Create root module that dot-sources all functions from Public/ and Private/
4. Create PSScriptAnalyzer settings to enforce style rules

**Definition of Done:**
- [ ] Module manifest validates with `Test-ModuleManifest`
- [ ] Root module loads without errors
- [ ] PSScriptAnalyzer settings file created
- [ ] Directory structure follows PowerShell conventions

---

### Task 2: Create Main Entry Point Function (Invoke-BPlusDBRefresh)

**Objective:** Create the main public function that orchestrates the entire database refresh process.

**Files:**
- Create: `src/BPlusDBRefresh/Public/Invoke-BPlusDBRefresh.ps1`

**Implementation Steps:**
1. Define function with proper `[CmdletBinding()]` attribute
2. Migrate all script parameters with:
   - Proper validation attributes (`[ValidateNotNullOrEmpty()]`, `[ValidateScript()]`)
   - Full parameter names and types
   - Comment-based parameter documentation
3. Add comprehensive comment-based help (Synopsis, Description, Parameters, Examples)
4. Create orchestration logic that calls other module functions in sequence
5. Implement proper error handling with Try/Catch blocks
6. Return structured output object with refresh results

**Parameter Block Structure:**
```powershell
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$BPEnvironment,

    [Parameter(Position = 1)]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$AspnetFilePath,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$IfasFilePath,

    [Parameter(Mandatory = $true, Position = 3)]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$SyscatFilePath,

    [switch]$TestingMode,

    [switch]$RestoreDashboards
)
```

**Definition of Done:**
- [ ] Function has complete comment-based help
- [ ] All parameters have validation attributes
- [ ] SupportsShouldProcess implemented for safety
- [ ] No diagnostics errors
- [ ] Follows OTBS formatting

---

### Task 3: Create Private Helper Functions

**Objective:** Create the private helper functions for module loading, MailKit management, and common operations.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Import-RequiredModule.ps1`
- Create: `src/BPlusDBRefresh/Private/Install-MailKitDependency.ps1`
- Create: `src/BPlusDBRefresh/Private/Test-MailKitAvailable.ps1`
- Create: `src/BPlusDBRefresh/Private/Write-LogMessage.ps1`
- Create: `src/BPlusDBRefresh/Private/Get-ScriptPath.ps1`

**Implementation Steps:**
1. Rename `Add-Module` to `Import-RequiredModule` (approved verb)
2. Convert to advanced function with `[CmdletBinding()]`
3. Add proper error handling:
   - Use `-ErrorAction Stop` on cmdlets
   - Throw terminating errors on failure instead of `Break`
4. Create `Write-LogMessage` wrapper for consistent logging:
   - Accept message and severity level
   - Call PSLogging functions internally
5. Create `Get-ScriptPath` helper to centralize path resolution
6. **Create `Install-MailKitDependency` function:**
   - Check if MailKit NuGet package is installed
   - Install via `Install-Package -Name MailKit -ProviderName NuGet` if missing
   - Also install MimeKit and dependent packages (System.Buffers, BouncyCastle)
   - Return installation status
7. **Create `Test-MailKitAvailable` function:**
   - Verify MailKit and MimeKit DLLs can be loaded
   - Return `$true`/`$false` with detailed error if unavailable

**Import-RequiredModule Structure:**
```powershell
function Import-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName
    )
    # Implementation with proper Try/Catch
}
```

**Install-MailKitDependency Structure:**
```powershell
function Install-MailKitDependency {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Check for NuGet provider
    # Install MailKit, MimeKit, and dependencies
    # Verify DLLs are accessible
}
```

**Definition of Done:**
- [ ] All functions use approved verbs
- [ ] Proper error handling (no `Break` statements)
- [ ] `[CmdletBinding()]` on all functions
- [ ] Consistent logging pattern established
- [ ] MailKit installation and verification functions working

---

### Task 4: Create Get-BPlusConfiguration Function

**Objective:** Create a function to parse and validate the INI configuration file.

**Files:**
- Create: `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1`

**Implementation Steps:**
1. Create advanced function with `[CmdletBinding()]` and `[OutputType([PSCustomObject])]`
2. Accept INI file path parameter with validation
3. Parse INI using PsIni module
4. Build structured configuration object with:
   - All database settings
   - File paths
   - Server lists
   - SMTP settings
5. Validate required settings exist
6. Return `[PSCustomObject]` instead of raw hashtable

**Output Object Structure:**
```powershell
[PSCustomObject]@{
    DatabaseServer    = $databaseServer
    IfasDatabase      = $ifasDatabase
    SyscatDatabase    = $syscatDatabase
    AspnetDatabase    = $aspnetDatabase
    FilePaths         = [PSCustomObject]@{ Data = ...; Log = ...; Images = ... }
    Servers           = @($serverList)
    SmtpSettings      = [PSCustomObject]@{ ... }
    # ... etc
}
```

**Definition of Done:**
- [ ] Returns strongly-typed PSCustomObject
- [ ] Validates all required configuration values
- [ ] Throws meaningful errors for missing config
- [ ] Has complete comment-based help
- [ ] Pester tests written

---

### Task 5: Create Show-ConfigurationReview Function

**Objective:** Create a function to display the configuration summary for user review.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Show-ConfigurationReview.ps1`
- Create: `src/BPlusDBRefresh/Private/Request-UserConfirmation.ps1`

**Implementation Steps:**
1. Accept configuration object from Get-BPlusConfiguration
2. Build formatted table display using `Format-Table`
3. Replace the complex `$arrReview` array building with cleaner approach
4. Use `Write-Host` for colored output where appropriate
5. Create separate `Request-UserConfirmation` function:
   - Use `$Host.UI.PromptForChoice()` for confirmation
   - Return `$true`/`$false` instead of calling `exit`

**Definition of Done:**
- [ ] Clean display formatting
- [ ] Removed redundant "add empty record" logic
- [ ] Confirmation function returns boolean
- [ ] No direct `exit` calls

---

### Task 6: Create Service Management Functions

**Objective:** Create functions to stop and start BusinessPlus services.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Stop-BPlusServices.ps1`
- Create: `src/BPlusDBRefresh/Private/Start-BPlusServices.ps1`

**Implementation Steps:**
1. Create `Stop-BPlusServices` function:
   - Accept server list and IPC daemon name
   - Stop services in order: btwfsvc, BTNETSVC, IPC daemon, W3SVC
   - Use proper error handling per service
   - Log each operation
2. Create `Start-BPlusServices` function (for potential future use):
   - Mirror stop logic for starting services
3. Use `Get-Service` with `-ErrorAction Stop` in Try/Catch

**Definition of Done:**
- [ ] Both stop and start functions created
- [ ] Proper error handling per service
- [ ] Returns service status results
- [ ] Logging integrated

---

### Task 7: Create Database Connection Functions

**Objective:** Create functions to backup and restore database connection configuration.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Backup-DatabaseConnectionInfo.ps1`
- Create: `src/BPlusDBRefresh/Private/Restore-DatabaseConnectionInfo.ps1`

**Implementation Steps:**
1. Create `Backup-DatabaseConnectionInfo`:
   - Query syscat `bsi_sys_blob` table
   - Query ifas `ifas_data` table
   - Return structured object with both datasets
   - Use parameterized SQL queries
2. Create `Restore-DatabaseConnectionInfo`:
   - Delete old records
   - Insert backed-up data
   - Validate restoration

**Definition of Done:**
- [ ] Parameterized SQL queries (no injection risk)
- [ ] Returns structured results
- [ ] Proper connection handling and disposal
- [ ] Error handling with rollback consideration

---

### Task 8: Create Restore-BPlusDatabase Function

**Objective:** Create the main database restoration function.

**Files:**
- Create: `src/BPlusDBRefresh/Private/Restore-BPlusDatabase.ps1`
- Create: `src/BPlusDBRefresh/Private/Build-FileMapping.ps1`

**Implementation Steps:**
1. Create `Build-FileMapping` helper:
   - Parse file drive configuration string
   - Build hashtable for dbatools `Restore-DbaDatabase`
2. Create `Restore-BPlusDatabase`:
   - Accept database name, backup path, file mapping
   - Call `Restore-DbaDatabase` with proper parameters
   - Log progress and results
   - Support `-WhatIf` via `ShouldProcess`

**Definition of Done:**
- [ ] Proper file mapping construction
- [ ] `SupportsShouldProcess` implemented
- [ ] Progress logging
- [ ] Returns restore result object

---

### Task 9: Externalize SQL Queries and Create Set-DatabasePermissions

**Objective:** Move SQL scripts to external files and create permission management function.

**Files:**
- Create: `src/BPlusDBRefresh/Resources/SQL/Set-AspnetPermissions.sql`
- Create: `src/BPlusDBRefresh/Resources/SQL/Set-IfasPermissions.sql`
- Create: `src/BPlusDBRefresh/Resources/SQL/Set-SyscatPermissions.sql`
- Create: `src/BPlusDBRefresh/Private/Set-DatabasePermissions.ps1`

**Implementation Steps:**
1. Extract SQL scripts from current inline here-strings
2. Use parameter placeholders in SQL files (e.g., `@AdminSource`, `@DatabaseName`)
3. Create `Set-DatabasePermissions` function:
   - Load SQL from resource files
   - Replace parameters using `$sql -replace '@param', $value`
   - Execute via `Invoke-Sqlcmd`
   - Log executed SQL for audit trail
4. Handle each database type (aspnet, ifas, syscat)

**SQL File Format:**
```sql
-- Set-IfasPermissions.sql
-- Parameters: @Database, @IusrSource, @IusrDestination, @AdminSource, @AdminDestination

USE [@Database]
GO

DROP USER [@IusrSource]
GO
-- ... etc
```

**Definition of Done:**
- [ ] All SQL externalized to .sql files
- [ ] Parameters properly replaced
- [ ] SQL logged for auditing
- [ ] Error handling for SQL execution failures

---

### Task 10: Create Workflow and User Management Functions

**Objective:** Create functions for disabling workflows, updating user accounts, and related operations.

**Files:**
- Create: `src/BPlusDBRefresh/Resources/SQL/Disable-Workflows.sql`
- Create: `src/BPlusDBRefresh/Resources/SQL/Update-UserAccounts.sql`
- Create: `src/BPlusDBRefresh/Private/Disable-BPlusWorkflows.ps1`
- Create: `src/BPlusDBRefresh/Private/Set-NuupausyText.ps1`
- Create: `src/BPlusDBRefresh/Private/Copy-DashboardFiles.ps1`

**Implementation Steps:**
1. Extract workflow disable SQL to external file
2. Create `Disable-BPlusWorkflows`:
   - Accept manager codes and testing mode flag
   - Build manager code list for SQL IN clause
   - Execute workflow and user account updates
3. Create `Set-NuupausyText`:
   - Update `au_audit_mstr` with environment text
   - Update `us_setting` with dashboard URL
4. Create `Copy-DashboardFiles`:
   - Validate source path exists
   - Copy with `-Force -Recurse`
   - Log copied files

**Definition of Done:**
- [ ] All SQL externalized
- [ ] Manager codes properly formatted for SQL
- [ ] Testing mode handled correctly
- [ ] Dashboard copy with validation

---

### Task 11: Create Notification Functions with Externalized HTML Template

**Objective:** Create the email notification system with externalized HTML template and proper MailKit integration.

**Files:**
- Create: `src/BPlusDBRefresh/Resources/Templates/CompletionEmail.html`
- Create: `src/BPlusDBRefresh/Private/Send-CompletionNotification.ps1`
- Create: `src/BPlusDBRefresh/Private/Restart-BPlusServers.ps1`

**Implementation Steps:**
1. Extract HTML email template:
   - Use `{{placeholder}}` syntax for variables
   - Keep responsive CSS intact
2. Create `Send-CompletionNotification`:
   - **Call `Test-MailKitAvailable` before attempting to send**
   - **If MailKit not available, call `Install-MailKitDependency` with user confirmation**
   - Load MailKit/MimeKit assemblies using verified paths from NuGet package location
   - Load template from Resources
   - Replace placeholders with actual values
   - Build email using MailKit (per Microsoft recommendation - Send-MailMessage is deprecated)
   - Attach log file
   - Proper error handling for SMTP failures
3. Create `Restart-BPlusServers`:
   - Accept server list
   - Use `Restart-Computer -Force -Wait`
   - Log reboot progress

**MailKit Usage (recommended over deprecated Send-MailMessage):**
```powershell
# Verify MailKit is available
if (-not (Test-MailKitAvailable)) {
    Install-MailKitDependency -Confirm
}

# Load assemblies from NuGet package location
$nugetPath = "$env:USERPROFILE\.nuget\packages"
Add-Type -Path "$nugetPath\mailkit\*\lib\net45\MailKit.dll"
Add-Type -Path "$nugetPath\mimekit\*\lib\net45\MimeKit.dll"

# Build and send email
$smtpClient = [MailKit.Net.Smtp.SmtpClient]::new()
$message = [MimeKit.MimeMessage]::new()
# ... configure and send
```

**Template Placeholders:**
```html
{{Environment}} - Environment name
{{RequestedBy}} - User who ran the script
{{CompletionMessage}} - Status message
{{Address}} - Street address for footer
```

**Definition of Done:**
- [ ] HTML template externalized and readable
- [ ] All placeholders documented
- [ ] **MailKit availability verified before sending**
- [ ] **MailKit installation automated if missing**
- [ ] MailKit integration working (NOT Send-MailMessage)
- [ ] SMTP error handling with meaningful messages

---

### Task 12: Create Pester Tests and PSScriptAnalyzer Configuration

**Objective:** Create comprehensive Pester tests and ensure PSScriptAnalyzer compliance.

**Files:**
- Create: `Tests/BPlusDBRefresh.Tests.ps1`
- Create: `Tests/Unit/Import-RequiredModule.Tests.ps1`
- Create: `Tests/Unit/Get-BPlusConfiguration.Tests.ps1`
- Create: `Tests/Unit/Build-FileMapping.Tests.ps1`
- Create: `Tests/Unit/MailKit.Tests.ps1`
- Create: `Tests/Integration/Invoke-BPlusDBRefresh.Tests.ps1`

**Implementation Steps:**
1. Create test structure mirroring module structure
2. Write unit tests for:
   - `Import-RequiredModule` - mock module availability
   - `Get-BPlusConfiguration` - test with sample INI
   - `Build-FileMapping` - test file structure parsing
   - `Test-MailKitAvailable` - verify MailKit detection logic
   - `Install-MailKitDependency` - mock package installation
3. Write integration test stubs for main workflow
4. Run PSScriptAnalyzer on all module files
5. Fix any remaining style violations
6. Create sample INI for testing

**Test Coverage Goals:**
- All public functions have tests
- Critical private functions have tests
- Edge cases for configuration parsing
- Error condition handling

**Definition of Done:**
- [ ] All tests pass (`Invoke-Pester`)
- [ ] PSScriptAnalyzer reports no errors
- [ ] Code coverage > 70% for public functions
- [ ] Test documentation complete

---

## Testing Strategy

### Unit Tests
- Test configuration parsing with valid/invalid INI files
- Test file mapping construction with various configurations
- Test parameter validation on public functions
- Mock external dependencies (dbatools, PsIni, SQL connections)

### Integration Tests
- Test module import and manifest validation
- Test end-to-end workflow with mocked database operations
- Test error handling paths

### Manual Verification
1. Import module: `Import-Module ./src/BPlusDBRefresh`
2. Run `Get-Command -Module BPlusDBRefresh` to verify exports
3. Run `Get-Help Invoke-BPlusDBRefresh -Full` to verify help
4. Run PSScriptAnalyzer: `Invoke-ScriptAnalyzer -Path ./src/BPlusDBRefresh -Recurse`

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing workflow | Medium | High | Preserve all original functionality; thorough testing |
| MailKit DLL path changes | Low | Medium | Document dependencies; add validation |
| SQL query parameter injection | Low | High | Use parameterized queries consistently |
| Service management failures | Medium | Medium | Comprehensive error handling; continue on single failures |
| Pester test complexity | Medium | Low | Start with critical path tests; expand coverage iteratively |

## Open Questions
- None at this time - all key decisions made during interview

## References
- [PoshCode PowerShell Practice and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- [Approved PowerShell Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [Pester Documentation](https://pester.dev/docs/quick-start)
