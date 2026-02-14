# CI/CD SQL Server Integration Tests Implementation Plan

Created: 2026-02-14
Status: VERIFIED
Approved: Yes
Iterations: 0
Worktree: No

> **Status Lifecycle:** PENDING → COMPLETE → VERIFIED
> **Iterations:** Tracks implement→verify cycles (incremented by verify phase)
>
> - PENDING: Initial state, awaiting implementation
> - COMPLETE: All tasks implemented
> - VERIFIED: All checks passed
>
> **Approval Gate:** Implementation CANNOT proceed until `Approved: Yes`
> **Worktree:** No — feature branch `feature/ci-sqlserver-integration` created directly

## Summary

**Goal:** Add a CI/CD integration test job that spins up SQL Server on Linux, creates a "bplus" database with stub tables, backs it up to `/tmp/`, then restores it to "bplustest1" using the module's `Get-BPlusConfiguration` and `Restore-BPlusDatabase` functions with a CI-specific example configuration file. This validates the module's core backup/restore workflow end-to-end in CI.

**Architecture:** New `integration` job added to the existing `ci.yml` workflow, running on `ubuntu-latest` with a SQL Server 2022 Linux service container. The job installs dbatools and Pester, then runs a dedicated Pester integration test file that exercises the real module functions against the live SQL Server instance. A small backwards-compatible change adds optional `-SqlCredential` to `Restore-BPlusDatabase` to support SQL authentication (required on Linux).

**Tech Stack:** GitHub Actions, SQL Server 2022 Linux (container), PowerShell Core, dbatools, Pester 5.x

## Scope

### In Scope

- Update JSON schema to accept Linux-style paths alongside Windows paths
- Add optional `-SqlCredential` parameter to `Restore-BPlusDatabase`
- Create minimal stub table SQL script for CI database setup
- Create CI-specific example configuration file (`bpcBPlusDBRefresh-ci.json`)
- Create Pester integration test for the backup/restore workflow
- Add `integration` job to `.github/workflows/ci.yml`
- Create feature branch `feature/ci-sqlserver-integration` and PR

### Out of Scope

- Testing `Set-DatabasePermissions`, `Disable-BPlusWorkflows`, or other post-restore operations (requires SQL logins and application-specific tables beyond stub schema)
- Testing `Backup-DatabaseConnectionInfo` / `Restore-DatabaseConnectionInfo` (requires `bsi_sys_blob` and `ifas_data` tables with specific schemas)
- Adding `-SqlCredential` to other functions (future enhancement if needed)
- Modifying existing Windows-based test/lint jobs
- Full schema for BusinessPlus tables (only stub columns referenced by existing SQL scripts)

## Prerequisites

- GitHub Actions runner with `ubuntu-latest` available
- `mcr.microsoft.com/mssql/server:2022-latest` Docker image accessible from GitHub Actions
- dbatools module compatible with PowerShell Core on Linux (dbatools v2.x supports this)

## Context for Implementer

> This section is critical for cross-session continuity. Write it for an implementer who has never seen the codebase.

- **Patterns to follow:**
  - CI workflow structure: `.github/workflows/ci.yml` — existing `test` and `lint` jobs use `windows-latest` with `pwsh` shell. The new `integration` job follows the same pattern but on `ubuntu-latest`.
  - Integration test pattern: `Tests/Integration/Invoke-BPlusDBRefresh.Tests.ps1` — dot-sources all Public + Private functions in `BeforeAll`.
  - Unit test pattern: `Tests/Unit/Build-FileMapping.Tests.ps1` — dot-sources individual function file, tests parameters and behavior.
  - SQL resource pattern: `Resources/SQL/Set-IfasPermissions.sql` — SQL files with `@Parameter` placeholders.

- **Conventions:**
  - OTBS brace style, 4-space indentation
  - PowerShell functions use approved verbs
  - Comment-based help on exported functions (not required for private functions but present on some)
  - Test files named `FunctionName.Tests.ps1`

- **Key files the implementer must read:**
  - `src/BPlusDBRefresh/Private/Restore-BPlusDatabase.ps1` — Contains both `Build-FileMapping` (nested) and `Restore-BPlusDatabase`. The `-SqlCredential` parameter gets added here.
  - `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1` — Config parser. Many fields are required (`$true`); CI config must provide all of them.
  - `bpcBPlusDBRefresh.schema.json` — JSON Schema with path patterns that need updating for Linux.
  - `bpcBPlusDBRefresh-sample.json` — Reference for CI config structure.
  - `Tests/Fixtures/TestConfig.json` — Fixture config used by existing tests.

- **Gotchas:**
  - `Build-FileMapping` already handles Linux paths (line 47: checks for drive letter, falls back to OS separator). No changes needed there.
  - `Get-BPlusConfiguration` requires all "required" fields even if only testing restore. CI config needs dummy values for SMTP, security accounts, servers, etc.
  - The JSON schema `filepathData`/`filepathLog` patterns enforce Windows-only paths (`^[A-Za-z]:\\\\.*$`). Must update before CI config will validate in IDEs.
  - `Restore-BPlusDatabase` has `[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]` on `-BackupPath` — the backup file must exist before calling restore.
  - The `$script:ModuleRoot` and `$script:ResourcesPath` variables are set by `BPlusDBRefresh.psm1` module loader. Integration tests that dot-source functions directly don't have these variables — `Get-SqlResourceContent` and `Get-ResourcePath` won't work. The CI test only needs `Get-BPlusConfiguration`, `Build-FileMapping`, and `Restore-BPlusDatabase` which don't use resource paths.

- **Domain context:**
  - The module refreshes BusinessPlus test environment databases by restoring production backups. The CI test simulates this: create a source DB ("bplus"), back it up, restore to a target DB ("bplustest1") using config-driven file mappings.
  - "fileDriveData" entries follow format `LogicalName:DriveType:PhysicalFileName` — e.g., `bplus:Data:bplustest1.mdf`. `Build-FileMapping` uses these to tell SQL Server where to place restored files.

## Progress Tracking

**MANDATORY: Update this checklist as tasks complete. Change `[ ]` to `[x]`.**

- [x] Task 1: Update JSON schema for cross-platform path support
- [x] Task 2: Add SqlCredential parameter to Restore-BPlusDatabase
- [x] Task 3: Create CI database setup SQL script and configuration file
- [x] Task 4: Create CI integration Pester tests
- [x] Task 5: Add integration job to CI workflow

**Total Tasks:** 5 | **Completed:** 5 | **Remaining:** 0

## Implementation Tasks

### Task 1: Update JSON Schema for Cross-Platform Path Support

**Objective:** Modify the JSON schema to accept both Windows-style paths (`D:\MSSQL\Data`) and Linux-style paths (`/var/opt/mssql/data`) for file path properties.

**Dependencies:** None

**Files:**

- Modify: `bpcBPlusDBRefresh.schema.json`

**Key Decisions / Notes:**

- Current pattern: `"^[A-Za-z]:\\\\.*$"` — only Windows paths
- New pattern: `"^([A-Za-z]:\\\\.*|/.+)$"` — Windows paths OR Unix absolute paths (starts with `/`, at least one char after)
- Apply to three properties: `filepathData`, `filepathLog`, `filepathImages`
- No changes to `Get-BPlusConfiguration.ps1` — it doesn't validate against the schema (schema is for IDE tooling only)

**Definition of Done:**

- [ ] `filepathData` pattern accepts both `D:\\MSSQL\\Data` and `/var/opt/mssql/data`
- [ ] `filepathLog` pattern accepts both Windows and Linux paths
- [ ] `filepathImages` pattern accepts both Windows and Linux paths (if present — it's optional)
- [ ] Existing Windows-only paths in `bpcBPlusDBRefresh-sample.json` and `Tests/Fixtures/TestConfig.json` still validate
- [ ] Empty strings and relative paths still rejected

**Verify:**

- `pwsh -c "'{\"filepathData\": \"/var/opt/mssql/data\"}' | ConvertFrom-Json"` — Linux path parses (basic sanity; full schema validation is IDE-side)
- Visual inspection that pattern regex is correct

### Task 2: Add SqlCredential Parameter to Restore-BPlusDatabase

**Objective:** Add an optional `-SqlCredential` parameter to `Restore-BPlusDatabase` that passes through to `Restore-DbaDatabase`, enabling SQL Server authentication for non-Windows environments (e.g., Linux CI).

**Dependencies:** None

**Files:**

- Modify: `src/BPlusDBRefresh/Private/Restore-BPlusDatabase.ps1`
- Create: `Tests/Unit/Restore-BPlusDatabase.Tests.ps1`

**Key Decisions / Notes:**

- Parameter type: `[PSCredential]`, optional (no `Mandatory`), default `$null`
- When provided, pass to `Restore-DbaDatabase -SqlCredential $SqlCredential`
- When not provided, existing behavior unchanged (Windows auth)
- Use splatting to conditionally include `-SqlCredential` only when provided, to avoid passing `$null` to dbatools
- Follow the existing parameter pattern in the function (CmdletBinding, Parameter attributes)
- `Build-FileMapping` is a nested function in the same file — it does NOT need SqlCredential (it builds paths, no SQL)

**Definition of Done:**

- [ ] `Restore-BPlusDatabase` accepts optional `-SqlCredential` parameter of type `[PSCredential]`
- [ ] When `-SqlCredential` is provided, it is passed to `Restore-DbaDatabase`
- [ ] When `-SqlCredential` is not provided, behavior is unchanged (no breaking change)
- [ ] Unit tests verify parameter exists and is optional
- [ ] Unit tests verify SqlCredential is passed through to Restore-DbaDatabase when provided
- [ ] Unit tests verify SqlCredential is NOT passed when omitted
- [ ] Existing `Build-FileMapping.Tests.ps1` still passes (no regression)
- [ ] PSScriptAnalyzer clean on modified file

**Verify:**

- `pwsh -c "Invoke-Pester ./Tests/Unit/Restore-BPlusDatabase.Tests.ps1 -CI"` — new tests pass
- `pwsh -c "Invoke-Pester ./Tests/Unit/Build-FileMapping.Tests.ps1 -CI"` — existing tests pass
- `pwsh -c "Invoke-ScriptAnalyzer -Path ./src/BPlusDBRefresh/Private/Restore-BPlusDatabase.ps1 -Settings ./PSScriptAnalyzerSettings.psd1"` — no findings

### Task 3: Create CI Database Setup SQL Script and Configuration File

**Objective:** Create the SQL script that sets up the "bplus" database with minimal stub tables, and create a CI-specific JSON configuration file that configures the module for Linux SQL Server restore operations.

**Dependencies:** Task 1

**Files:**

- Create: `src/BPlusDBRefresh/Resources/SQL/CI-CreateTables.sql`
- Create: `bpcBPlusDBRefresh-ci.json`

**Key Decisions / Notes:**

- **SQL Script:** Creates 5 stub tables with only the columns referenced in existing SQL scripts:
  - `wf_model` — columns: `wf_model_id VARCHAR(50)`, `wf_status CHAR(1)`
  - `wf_schedule` — columns: `wf_model_id VARCHAR(50)`, `wf_status CHAR(1)`
  - `wf_instance` — columns: `wf_model_id VARCHAR(50)`, `wf_status CHAR(1)`
  - `us_usno_mstr` — columns: `us_email VARCHAR(255)`, `us_status CHAR(1)`, `us_mgr_cd VARCHAR(20)`
  - `hr_empmstr` — columns: `e_mail VARCHAR(255)`
  - Each table gets a few seed rows (3-5) so restore verification can check row counts
- **SQL Script** should also include `bsi_sys_blob` and `ifas_data` tables (referenced by `Backup-DatabaseConnectionInfo`) with minimal columns to make the schema more complete, though they won't be tested in the CI workflow
- **CI Config:** Environment name `CI`, pointing to `localhost` SQL Server with Linux paths:
  - `sqlServer`: `localhost`
  - `database`: `bplustest1` (restore target name)
  - `filepathData`: `/var/opt/mssql/data`
  - `filepathLog`: `/var/opt/mssql/data` (Linux default: data and log in same directory)
  - `fileDriveData`: `["bplus:Data:bplustest1.mdf", "bplus_log:Log:bplustest1_log.ldf"]`
  - Non-database fields (security, SMTP, servers) get placeholder values
  - No `$schema` reference (schema path patterns are for IDE validation; CI config uses Linux paths that validate with updated schema)
- **Config includes comments** explaining it's for CI use, with references to the sample config for production usage

**Definition of Done:**

- [ ] `CI-CreateTables.sql` creates all 5 stub tables with correct column names and types
- [ ] Each table has 3-5 seed data rows for verification
- [ ] `bpcBPlusDBRefresh-ci.json` loads successfully via `Get-BPlusConfiguration -Path ./bpcBPlusDBRefresh-ci.json -Environment 'CI'`
- [ ] Config returns `IfasDatabase` = `bplustest1`, `DatabaseServer` = `localhost`
- [ ] Config file drive mappings produce correct Linux paths via `Build-FileMapping`

**Verify:**

- `pwsh -c "$config = Get-BPlusConfiguration -Path ./bpcBPlusDBRefresh-ci.json -Environment 'CI'; $config.IfasDatabase"` — returns `bplustest1` (requires dot-sourcing functions first)
- Visual inspection of SQL script for correct table/column names

### Task 4: Create CI Integration Pester Tests

**Objective:** Write a Pester test file that validates the full backup/restore workflow against a live SQL Server instance, exercising the module's real functions.

**Dependencies:** Task 2, Task 3

**Files:**

- Create: `Tests/Integration/CI-SqlServer.Tests.ps1`

**Key Decisions / Notes:**

- Test file dot-sources all Public + Private functions (same pattern as existing integration tests)
- Uses dbatools directly for: creating the "bplus" database, running the setup SQL, performing backup (these aren't module functions)
- Uses module functions for: loading CI config (`Get-BPlusConfiguration`), restoring database (`Restore-BPlusDatabase` with `-SqlCredential`)
- SQL Server credentials: SA user with password from environment variable `$env:SA_PASSWORD` (set by CI workflow)
- Test structure:
  1. **Setup Context:** Create "bplus" database, run `CI-CreateTables.sql`, insert seed data
  2. **Backup Context:** Use `Backup-DbaDatabase` to create `/tmp/bplus.bak`, verify file exists
  3. **Configuration Context:** Load CI config via `Get-BPlusConfiguration`, verify key properties
  4. **Restore Context:** Call `Restore-BPlusDatabase` with `-SqlCredential`, verify "bplustest1" exists
  5. **Verification Context:** Query restored database, verify tables exist and row counts match
- Tag tests with `-Tag 'CI'` so they can be selectively run
- Tests are designed to run sequentially (Pester runs `Describe` blocks top-to-bottom, and `Context` blocks within them in order)

**Definition of Done:**

- [ ] Test file follows existing integration test patterns (dot-source in BeforeAll)
- [ ] Tests cover: database creation, table creation, backup, config loading, restore via module function, data verification
- [ ] Tests use `$env:SA_PASSWORD` for SQL credentials (not hardcoded)
- [ ] Tests verify restored database has all 5 expected tables
- [ ] Tests verify restored data row counts match source
- [ ] Test file passes PSScriptAnalyzer (test files exempt from line count limits)

**Verify:**

- `pwsh -c "Invoke-ScriptAnalyzer -Path ./Tests/Integration/CI-SqlServer.Tests.ps1 -Settings ./PSScriptAnalyzerSettings.psd1"` — no findings
- Test will be fully verified when CI workflow runs in Task 5

### Task 5: Add Integration Job to CI Workflow

**Objective:** Add an `integration` job to the existing CI workflow that runs SQL Server 2022 on Linux and executes the CI integration Pester tests.

**Dependencies:** Task 4

**Files:**

- Modify: `.github/workflows/ci.yml`

**Key Decisions / Notes:**

- Job name: `integration` (display name: "SQL Server Integration")
- Runner: `ubuntu-latest`
- Shell: `pwsh` (PowerShell Core is pre-installed on Ubuntu runners)
- SQL Server: `mcr.microsoft.com/mssql/server:2022-latest` as a service container
  - `ACCEPT_EULA: Y`
  - `MSSQL_SA_PASSWORD` set via environment (strong password for SA)
  - Port 1433 mapped
  - Health check using sqlcmd to verify SQL Server is ready
- Steps:
  1. Checkout code
  2. Install dbatools and Pester modules (`timeout-minutes: 5`, `-ErrorAction Stop`, matching existing ci.yml pattern)
  3. Wait for SQL Server to be ready (retry loop using dbatools `Connect-DbaInstance`)
  4. Run Pester: `Invoke-Pester -Path ./Tests/Integration/CI-SqlServer.Tests.ps1 -CI`
- Follow exact patterns from existing `test` and `lint` jobs for module installation (pinned versions, `-Scope CurrentUser`, `-SkipPublisherCheck`)
- Environment variable `SA_PASSWORD` passed to the Pester step so tests can build credentials
- Runs in parallel with existing `test` and `lint` jobs (no `needs:` dependency)
- Inherits existing concurrency settings from workflow

**Definition of Done:**

- [ ] CI workflow has three jobs: `test`, `lint`, `integration`
- [ ] Integration job uses `ubuntu-latest` with SQL Server 2022 service container
- [ ] SQL Server health check ensures service is ready before tests run
- [ ] dbatools and Pester are installed in the job
- [ ] Pester runs `Tests/Integration/CI-SqlServer.Tests.ps1` with `-CI` flag
- [ ] SA password is passed as environment variable, not hardcoded in test file
- [ ] Job fails if any Pester test fails (exit code propagation)

**Verify:**

- Push to feature branch and observe GitHub Actions run
- `gh run list --workflow=CI --branch=feature/ci-sqlserver-integration` — shows integration job
- `gh run view <id>` — all three jobs (test, lint, integration) pass

## Testing Strategy

- **Unit tests:** `Restore-BPlusDatabase.Tests.ps1` — validates SqlCredential parameter exists, is optional, passes through to `Restore-DbaDatabase` when provided, omitted when not provided. Uses mocked `Restore-DbaDatabase`.
- **Integration tests:** `CI-SqlServer.Tests.ps1` — end-to-end validation against live SQL Server: create DB → create tables → insert data → backup → load config → restore → verify tables and data.
- **Regression:** Existing `Build-FileMapping.Tests.ps1` and all other unit/integration tests must continue passing.
- **CI validation:** Push feature branch, verify all three CI jobs pass.

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| dbatools incompatible with PowerShell Core on Linux | Low | High | dbatools v2.x officially supports Linux/PS Core. Pin version in CI install step. If it fails, fall back to sqlcmd for backup/restore and test only config/file-mapping via module. |
| SQL Server container fails to start in CI | Low | High | Health check with retry loop (30 retries, 2s interval). Service container `options` include health check command. |
| Default logical file names differ from expected | Low | Medium | Query `Restore-DbaDatabase -OutputScriptOnly` or `Read-DbaBackupHeader` in test to discover actual logical names before restore, rather than assuming "bplus" and "bplus_log". |
| SA password policy rejects test password | Low | Low | Use a password that meets SQL Server 2022 complexity requirements (uppercase, lowercase, number, special char, 12+ chars). |

## Open Questions

None — all design decisions have been resolved through user interview.

### Deferred Ideas

- Add `-SqlCredential` to other SQL-touching functions (`Backup-DatabaseConnectionInfo`, `Set-DatabasePermissions`, `Disable-BPlusWorkflows`) for full Linux/SQL Auth support
- Test post-restore operations (permissions, workflow disabling) against live SQL Server
- Add code coverage reporting to CI integration tests
