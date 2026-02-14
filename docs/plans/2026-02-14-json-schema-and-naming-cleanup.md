# JSON Schema and Naming Cleanup Implementation Plan

Created: 2026-02-14
Status: VERIFIED
Approved: Yes
Iterations: 1
Worktree: No

> **Status Lifecycle:** PENDING → COMPLETE → VERIFIED
> **Iterations:** Tracks implement→verify cycles (incremented by verify phase)
>
> - PENDING: Initial state, awaiting implementation
> - COMPLETE: All tasks implemented
> - VERIFIED: All checks passed
>
> **Approval Gate:** Implementation CANNOT proceed until `Approved: Yes`
> **Worktree:** No - work directly on current branch

## Summary

**Goal:** Create a JSON Schema file for configuration validation, update samples to reference the schema, rename all `hps`-prefixed files to use `bpc` prefix, replace all organization references (Highline/HPS → BusinessPlus Community), remove HPS module dependencies, and create a new BPC.Utils GitHub repository.

**Architecture:** JSON Schema will live alongside config files in project root. File renaming follows best practice of using organization prefix (`bpc` for BusinessPlus Community). All internal references updated to BusinessPlus Community branding.

**Tech Stack:** JSON Schema (Draft 2020-12), gh CLI for GitHub operations

## Scope

### In Scope

- Create `bpcBPlusDBRefresh.schema.json` with complete validation rules
- Update `bpcBPlusDBRefresh-sample.json` with `$schema` reference
- Rename all files: `hpsBPlusDBRestore*` → `bpcBPlusDBRefresh*`
- Update all code/docs references to renamed files
- Replace "Highline Public Schools" / "Highline School District" / "Puyallup School District" → "BusinessPlus Community"
- Remove `.devcontainer/install-hps-modules.sh` and all HPS.Utils/HPS.IIQ references
- Remove VSCode spell-check ignore entries for `hps`/`highlineschools`/`hpsinfra`/`HPSDW`
- Create empty `BPC.Utils` repository under BusinessPlus-Community organization via `gh`

### Out of Scope

- Renaming assets in `context/sx-vault-main/` (external team vault assets)
- Modifying completed historical plan files in `docs/plans/2026-01-10-*.md`
- Changing external package names (`HPS.Utils`, `HPS.IIQ` are 3rd-party and can't be renamed)

## Prerequisites

- `gh` CLI installed and authenticated with GitHub
- Write access to `https://github.com/orgs/BusinessPlus-Community/` organization
- No uncommitted changes (clean working tree recommended for safe file renaming)

## Context for Implementer

**File Naming Convention:**
- Old prefix: `hps` (Highline Public Schools)
- New prefix: `bpc` (BusinessPlus Community)
- Pattern: `bpcBPlusDBRefresh` (organization prefix + application name)

**Best Practice for JSON Schema:**
- Schema file lives alongside config files (project root, not `schemas/` subdirectory)
- Use Draft 2020-12 for modern validation features
- `$schema` property in JSON files enables IDE validation/autocomplete

**Organization Name Standardization:**
- Highline Public Schools → BusinessPlus Community
- Highline School District → BusinessPlus Community
- Puyallup School District → BusinessPlus Community (already present, needs consistency)

**Key Files to Update:**
- Configuration samples: `hpsBPlusDBRestore-sample.json`, `hpsBPlusDBRestore-sample.ini`
- Module code: `src/BPlusDBRefresh/Public/*.ps1` (default paths, examples, log names)
- Documentation: `README.md`, `CLAUDE.md`, `.claude/rules/project.md`
- Legacy script: `hpsBPlusDBRestore.ps1` (DELETE - superseded by module)

**Dependencies Between Naming Changes:**
- Schema file MUST be created before updating `$schema` references
- Files MUST be renamed before updating references in code
- Git will track renames automatically if done correctly

## Progress Tracking

**MANDATORY: Update this checklist as tasks complete. Change `[ ]` to `[x]`.**

- [x] Task 1: Create JSON Schema file
- [x] Task 2: Update sample JSON with schema reference
- [x] Task 3: Rename configuration files
- [x] Task 4: Update module code references
- [x] Task 5: Update documentation files
- [x] Task 6: Clean up HPS module dependencies
- [x] Task 7: Update VSCode settings
- [x] Task 8: Delete legacy script
- [x] Task 9: Create BPC.Utils repository

- [x] Task 10: [VERIFY-FIX] Update README.md config structure to environments-nested format
- [x] Task 11: [VERIFY-FIX] Update CLAUDE.md config structure to environments-nested format
- [x] Task 12: [VERIFY-FIX] Update integration test to remove stale PsIni mock
- [x] Task 13: [VERIFY-FIX] Add additionalProperties: false to JSON Schema

> Extended 2026-02-14: Tasks 10-13 added for should_fix issues found during verification (Iteration 1)

**Total Tasks:** 13 | **Completed:** 13 | **Remaining:** 0

**Task Dependencies:**
- Task 1 → Task 3 (schema must exist before renaming)
- Task 3 → Task 2 (files renamed before modification to preserve git history)
- Task 3 → Task 4 (files renamed before code updates)
- Task 3 → Task 5 (files renamed before doc updates)

## Implementation Tasks

### Task 1: Create JSON Schema File

**Objective:** Create `bpcBPlusDBRefresh.schema.json` that validates the configuration file structure with complete type definitions, required fields, and constraints.

**Dependencies:** None

**Files:**
- Create: `bpcBPlusDBRefresh.schema.json`

**Key Decisions / Notes:**
- Use JSON Schema Draft 2020-12 (`"$schema": "https://json-schema.org/draft/2020-12/schema"`)
- Schema validates the structure seen in `hpsBPlusDBRestore-sample.json`
- Define `environments` as an object with pattern properties for environment names
- All environment-specific fields defined in nested schema
- SMTP settings as separate required object
- Include descriptions for each field to provide inline documentation

**Definition of Done:**
- [ ] Schema file created with Draft 2020-12
- [ ] All fields from sample config are defined in schema
- [ ] Required fields marked as required
- [ ] String patterns defined for structured fields (e.g., file paths, UNC paths)
- [ ] Array fields have `minItems: 1` where empty arrays would cause failures (environmentServers, managerCodes, fileDriveData, fileDriveSyscat)
- [ ] Schema validates sample config using CLI validator: `check-jsonschema --schemafile bpcBPlusDBRefresh.schema.json hpsBPlusDBRestore-sample.json` (install via `pip install check-jsonschema` if needed)

**Verify:**
- Schema file exists and is valid JSON
- CLI validator confirms schema validates sample config without errors

---

### Task 2: Update Sample JSON with Schema Reference

**Objective:** Add `$schema` property to sample JSON files pointing to the new schema file, enabling IDE validation and autocomplete. Note: existing `$schema` field contains a description string (misuse of the field) - this will be replaced with the correct schema URI.

**Dependencies:** Task 3 (files must be renamed first to avoid breaking git rename detection)

**Files:**
- Modify: `bpcBPlusDBRefresh-sample.json` (after rename in Task 3)
- Modify: `Tests/Fixtures/TestConfig.json`

**Key Decisions / Notes:**
- Task ordering: Files renamed in Task 3 BEFORE schema reference is added (prevents modifications from breaking git's rename detection)
- `$schema` property should be first line in JSON file for discoverability
- Use relative path: `./bpcBPlusDBRefresh.schema.json` for sample, `../../bpcBPlusDBRefresh.schema.json` for test fixture
- Existing `$schema` field contains description text - verify no code depends on reading this field before replacing it
- Update `_comment` to reference new `bpc` prefix: `"Copy this file to bpcBPlusDBRefresh.json"`

**Definition of Done:**
- [ ] Verified no code reads `$schema` field expecting description string (grep for `config.*\$schema` or similar)
- [ ] `$schema` property set to correct relative path in sample JSON (first line, replaces old description)
- [ ] `_comment` updated to reference `bpcBPlusDBRefresh.json`
- [ ] `Tests/Fixtures/TestConfig.json` updated with schema reference
- [ ] Verified if `Tests/Fixtures/TestConfig.ini` needs any related updates
- [ ] VSCode shows no validation errors when editing the file

**Verify:**
- Open sample JSON in VSCode - should show autocomplete and validation
- No schema validation errors
- `grep -r '\$schema' src/` confirms no code depends on $schema being a description

---

### Task 3: Rename Configuration Files

**Objective:** Rename all `hpsBPlusDBRestore*` files to `bpcBPlusDBRefresh*` using git mv to preserve history. Rename BEFORE modifying files to ensure git's rename detection works.

**Dependencies:** Task 1 (schema file created)

**Files:**
- Rename: `hpsBPlusDBRestore-sample.json` → `bpcBPlusDBRefresh-sample.json`
- Rename: `hpsBPlusDBRestore-sample.ini` → `bpcBPlusDBRefresh-sample.ini`
- Update: `bpcBPlusDBRefresh.schema.json` (`$id` field to match new filename if present)

**Key Decisions / Notes:**
- Use `git mv` for renames to preserve git history
- CRITICAL: Rename files BEFORE Task 2 modifies them (preserves similarity for git rename detection)
- New naming convention: `bpcBPlusDBRefresh` (org prefix `bpc` + app name)
- If schema has `$id` field: update to `./bpcBPlusDBRefresh.schema.json` (relative file path, not URL, to avoid external reference issues)

**Definition of Done:**
- [ ] Sample JSON renamed with git history preserved
- [ ] Sample INI renamed with git history preserved
- [ ] Schema `$id` field updated to `./bpcBPlusDBRefresh.schema.json` if field exists
- [ ] Verified schema $id update doesn't break any external tools or caching

**Verify:**
- `git status` shows renames, not delete+add
- All file references resolve correctly

---

### Task 4: Update Module Code References

**Objective:** Update default configuration paths, log file names, and documentation examples in PowerShell module code to use new `bpc` prefix.

**Dependencies:** Task 3 (files renamed)

**Files:**
- Modify: `src/BPlusDBRefresh/Public/Invoke-BPlusDBRefresh.ps1` (default paths, log name)
- Modify: `src/BPlusDBRefresh/Public/Get-BPlusConfiguration.ps1` (example paths)
- Modify: `src/BPlusDBRefresh/Public/Convert-IniToJson.ps1` (example paths)

**Key Decisions / Notes:**
- Update default `$ConfigurationPath` from `hpsBPlusDBRestore.ini` → `bpcBPlusDBRefresh.ini`
- Update log file name from `hpsBPlusDBRestore.log` → `bpcBPlusDBRefresh.log`
- Update example paths in comment-based help
- Pattern to find: `hpsBPlusDBRestore` → replace with `bpcBPlusDBRefresh`

**Definition of Done:**
- [ ] Default config path updated in `Invoke-BPlusDBRefresh.ps1:135,137`
- [ ] Log file name updated in `Invoke-BPlusDBRefresh.ps1:143`
- [ ] Example paths updated in all comment-based help `.EXAMPLE` sections (Get-BPlusConfiguration.ps1:25, Convert-IniToJson.ps1:22,26)
- [ ] All `hpsBPlusDBRestore` references categorized and updated: (1) File paths in examples/defaults = UPDATED, (2) Log messages = UPDATED for consistency, (3) Historical version strings = KEPT for auditability
- [ ] No remaining references to `hpsBPlusDBRestore` in `src/` directory (case-insensitive check)

**Verify:**
- `grep -ri "hpsbplusdbrestore" src/` returns no matches (case-insensitive)
- Module functions use correct default paths
- All example paths in comment-based help reference `bpcBPlusDBRefresh`

---

### Task 5: Update Documentation Files

**Objective:** Replace all `hpsBPlusDBRestore` references with `bpcBPlusDBRefresh` and update organization names in README, CLAUDE.md, and project rules.

**Dependencies:** Task 3 (files renamed)

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `.claude/rules/project.md`

**Key Decisions / Notes:**
- File name references: `hpsBPlusDBRestore` → `bpcBPlusDBRefresh`
- Organization names:
  - "Puyallup School District" → "BusinessPlus Community"
  - "Highline Public Schools" → "BusinessPlus Community" (if any remain)
  - "Highline School District" → "BusinessPlus Community" (if any remain)
- Update copyright statements to BusinessPlus Community
- Update module manifest: `src/BPlusDBRefresh/BPlusDBRefresh.psd1` (CompanyName, Copyright)

**Definition of Done:**
- [ ] All file references updated in README.md
- [ ] All file references updated in CLAUDE.md
- [ ] All file references updated in .claude/rules/project.md
- [ ] Module manifest CompanyName set to "BusinessPlus Community"
- [ ] Module manifest Copyright updated to "(c) 2021-2026 BusinessPlus Community. All rights reserved."
- [ ] Organization names standardized to "BusinessPlus Community" (Puyallup/Highline replaced)
- [ ] README.md includes migration guide section for users upgrading from old filenames
- [ ] No references to Puyallup/Highline remaining (except in historical plan files)

**Verify:**
- `grep -ri "hpsbplusdbrestore" README.md CLAUDE.md .claude/` returns no matches
- `grep -ri "puyallup\|highline" --exclude-dir=docs/plans .` returns no matches in active files
- README.md contains migration instructions for renaming config files

---

### Task 6: Clean Up HPS Module Dependencies

**Objective:** Remove all references to HPS.Utils and HPS.IIQ modules from the project.

**Dependencies:** None

**Files:**
- Delete: `.devcontainer/install-hps-modules.sh`
- Modify: `.devcontainer/devcontainer.json` (remove postCreateCommand if it references the script)

**Key Decisions / Notes:**
- Delete the entire script file - HPS modules are external and no longer needed
- Check if `.devcontainer/devcontainer.json` has a `postCreateCommand` that runs this script
- No other files reference HPS.Utils or HPS.IIQ (verified via grep)

**Definition of Done:**
- [ ] `.devcontainer/install-hps-modules.sh` deleted
- [ ] `.devcontainer/devcontainer.json` updated if it referenced the script
- [ ] No references to HPS.Utils or HPS.IIQ remain in codebase

**Verify:**
- `grep -r "HPS\\.Utils\|HPS\\.IIQ" .devcontainer/` returns no matches
- Deleted script file no longer exists

---

### Task 7: Update VSCode Settings

**Objective:** Remove HPS-specific entries from VSCode spell-check ignore list.

**Dependencies:** None

**Files:**
- Modify: `.vscode/settings.json`

**Key Decisions / Notes:**
- Remove from `cSpell.ignoreWords`: `HPSDW`, `highlineschools`, `hpsinfra`
- Keep other entries that are still relevant (e.g., `Birge`, `Dbatools`)

**Definition of Done:**
- [ ] `HPSDW` removed from ignore list
- [ ] `highlineschools` removed from ignore list
- [ ] `hpsinfra` removed from ignore list
- [ ] JSON file remains valid

**Verify:**
- `.vscode/settings.json` is valid JSON
- Removed entries no longer present

---

### Task 8: Delete Legacy Script

**Objective:** Remove the superseded v1.x monolithic script from project root after verifying no external automation depends on it.

**Dependencies:** None

**Files:**
- Delete: `hpsBPlusDBRestore.ps1`

**Key Decisions / Notes:**
- This script has been fully replaced by the `src/BPlusDBRefresh/` module (v2.0+)
- CRITICAL: Verify external automation before deletion (Task Scheduler, cron jobs, CI/CD pipelines)
- Delete using `git rm` to record removal in history

**Definition of Done:**
- [ ] Verified no external automation references this script (checked Windows Task Scheduler if available, searched for wrapper scripts in repo)
- [ ] Documented any external consumers that need migration before deletion can proceed safely
- [ ] `hpsBPlusDBRestore.ps1` deleted from project root
- [ ] Git history records the deletion

**Verify:**
- File no longer exists in project root
- `git status` shows deletion
- If external automation found, documented migration path for user

---

### Task 9: Create BPC.Utils Repository

**Objective:** Create an empty GitHub repository named `BPC.Utils` under the BusinessPlus-Community organization using the `gh` CLI, after verifying user has necessary permissions.

**Dependencies:** None

**Files:**
- None (external GitHub operation)

**Key Decisions / Notes:**
- Organization: `BusinessPlus-Community`
- Repository name: `BPC.Utils`
- Visibility: Private (recommended for utility libraries)
- Initialize with: README.md
- Description: "BusinessPlus Community shared utility library"
- Use `gh repo create` command
- CRITICAL: Verify org permissions before attempting creation to avoid end-of-workflow failures

**Definition of Done:**
- [ ] Verified user has org access: `gh api /orgs/BusinessPlus-Community --jq ".login"` succeeds
- [ ] Verified user role allows repo creation: `gh api /orgs/BusinessPlus-Community/memberships/$(gh api /user --jq .login) --jq ".role"` returns "admin" OR org allows member repo creation
- [ ] Repository created successfully via `gh` CLI: `gh repo create BusinessPlus-Community/BPC.Utils --private --description "BusinessPlus Community shared utility library" --confirm`
- [ ] Repository is accessible at `https://github.com/BusinessPlus-Community/BPC.Utils`
- [ ] Repository initialized with README

**Verify:**
- `gh repo view BusinessPlus-Community/BPC.Utils` shows repository details
- Repository URL is accessible
- If permissions insufficient, document that user must request repo creation permissions from org admin

---

## Testing Strategy

**Unit Tests:** No changes needed - tests reference `TestConfig.json` which will be updated in Task 2.

**Integration Tests:** No changes needed - same as unit tests.

**Manual Verification:**
1. Import module: `Import-Module ./src/BPlusDBRefresh/BPlusDBRefresh.psd1`
2. Verify default paths: `Get-Command Invoke-BPlusDBRefresh | Select-Object -ExpandProperty Parameters | Select-Object ConfigurationPath`
3. Check sample config validates against schema in VSCode
4. Verify no remaining `hps` references: `grep -r "hps\|HPS" --exclude-dir=.git --exclude-dir=context --exclude-dir=docs/plans .`

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing user configs | High | Medium | Add "Breaking Changes" section to README.md with step-by-step migration: (1) Backup existing config, (2) Rename `hpsBPlusDBRestore.json` → `bpcBPlusDBRefresh.json`, (3) Update any wrapper scripts referencing old filename. Module code emits clear error if old filename detected. |
| Git history lost on rename | Low | Low | Use `git mv` for all renames. Rename files BEFORE modifying them (Task 3 before Task 2) to preserve similarity for git rename detection. |
| Broken file references after rename | Medium | High | Case-insensitive grep-verify all references updated before committing. Categorize each match (file paths vs log messages vs historical strings). |
| GitHub org permissions insufficient | Low | High | Task 9 verifies org access and role BEFORE attempting repo creation. If insufficient permissions, document that user must request permissions from org admin. |
| External automation still calling old script | Medium | High | Task 8 checks for external automation (Task Scheduler, wrapper scripts) before deleting legacy script. Document any external consumers and coordinate migration to module-based invocation. |

## Open Questions

None - all design decisions have been clarified with user.

### Deferred Ideas

None
