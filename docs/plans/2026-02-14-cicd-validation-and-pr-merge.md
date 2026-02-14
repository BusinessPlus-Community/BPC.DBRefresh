# CI/CD Validation and PR Merge Implementation Plan

Created: 2026-02-14
Status: PENDING
Approved: Yes
Iterations: 0
Worktree: No

> **Status Lifecycle:** PENDING -> COMPLETE -> VERIFIED
> **Iterations:** Tracks implement->verify cycles (incremented by verify phase)

## Summary

**Goal:** Create a GitHub Actions CI workflow for the PowerShell module, validate all checks pass locally, create a PR from `feature/json-config-migration` to `main`, monitor CI via `gh`, fix any issues, squash merge, and clean up.

**Architecture:** GitHub Actions workflow running Pester tests and PSScriptAnalyzer on push/PR events targeting `main`. Uses `windows-latest` runner since the module targets PowerShell 5.1+ with SQL Server dependencies.

**Tech Stack:** GitHub Actions, Pester v5.x, PSScriptAnalyzer, PowerShell, `gh` CLI

## Scope

### In Scope

- Create `.github/workflows/ci.yml` with Pester tests and PSScriptAnalyzer
- Run all CI checks locally and fix any failures
- Commit CI workflow and any fixes, push to remote
- Create PR from `feature/json-config-migration` to `main`
- Monitor CI pipeline via `gh pr checks` and fix failures
- Request Copilot code review if available
- Squash merge PR once CI passes
- Delete merged branch and pull latest main

### Out of Scope

- CD/deployment pipeline
- Code coverage reporting services
- Branch protection rules
- Snyk security scanning integration (referenced in `.github/instructions/` but not implemented in this plan)

## Prerequisites

- `gh` CLI authenticated (already configured)
- PowerShell with Pester and PSScriptAnalyzer installed in devcontainer
- No pending uncommitted changes (clean working tree except `.qlty/` which is gitignored)

## Context for Implementer

- **CI workflow doesn't exist yet** - `.github/workflows/` directory needs to be created. An old workflow existed on a previous branch (`feature/module-conversion`) but was never merged to `main`.
- **Local CI checks** - Run `Invoke-Pester ./Tests` and `Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1` to validate locally before pushing.
- **Branch state** - `feature/json-config-migration` is 8 commits ahead of `main`. No branch protection on `main`.
- **Repo** - Public repo at `BusinessPlus-Community/BPC.DBRefresh`, default branch is `main`.
- **Merge strategy** - Squash merge to keep main history clean.
- **PSScriptAnalyzer config** - `PSScriptAnalyzerSettings.psd1` at project root defines rules (OTBS, 4-space indent, approved verbs, etc.).

## Progress Tracking

- [x] Task 1: Create GitHub Actions CI workflow
- [x] Task 2: Run CI checks locally and fix failures
- [ ] Task 3: Commit, push, and create PR
- [ ] Task 4: Monitor CI, fix failures, merge, and clean up

**Total Tasks:** 4 | **Completed:** 2 | **Remaining:** 2

## Implementation Tasks

### Task 1: Create GitHub Actions CI Workflow

**Objective:** Create a GitHub Actions workflow that runs Pester tests and PSScriptAnalyzer on push and PR events.

**Dependencies:** None

**Files:**

- Create: `.github/workflows/ci.yml`

**Key Decisions / Notes:**

- Use `windows-latest` runner (PowerShell module targets Desktop 5.1+)
- Trigger on `push` to `main` and `pull_request` targeting `main`
- Two jobs: `test` (Invoke-Pester) and `lint` (PSScriptAnalyzer)
- Install modules with explicit versions and timeouts:
  - `Install-Module -Name Pester -RequiredVersion 5.6.1 -Force -Scope CurrentUser -SkipPublisherCheck -ErrorAction Stop -Verbose`
  - `Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -ErrorAction Stop -Verbose`
- Add `timeout-minutes: 5` on install steps to detect PSGallery hangs
- Use PowerShell-native paths for Windows runner compatibility:
  - `Invoke-Pester -Path (Join-Path $PWD 'Tests')` (not `./Tests`)
  - `Invoke-ScriptAnalyzer -Path (Join-Path $PWD 'src') -Settings (Join-Path $PWD 'PSScriptAnalyzerSettings.psd1')`
- Do NOT install dbatools/PSLogging (tests mock these dependencies)
- Verify tests work without these modules in a clean `pwsh -NoProfile` session locally (Task 2)

**Definition of Done:**

- [ ] `.github/workflows/ci.yml` exists with valid YAML syntax
- [ ] Workflow triggers on push to main and PRs targeting main
- [ ] Pester test job runs all tests from `./Tests`
- [ ] PSScriptAnalyzer job uses project settings file
- [ ] Workflow YAML validated via `gh workflow view` after push (catches GitHub Actions schema errors beyond basic YAML syntax)

**Verify:**

- `cat .github/workflows/ci.yml` - File exists with correct structure
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` - Valid YAML syntax

### Task 2: Run CI Checks Locally and Fix Failures

**Objective:** Execute the same checks the CI workflow will run and fix any issues found.

**Dependencies:** Task 1

**Files:**

- Modify: Any files with test or linting failures (TBD based on results)

**Key Decisions / Notes:**

- First, run tests in a **clean `pwsh -NoProfile` session** to verify mocks work without dbatools/PSLogging installed (simulates CI environment)
- Run `Invoke-Pester ./Tests` - expect 150 passed, 0 failed, 3 skipped (from previous session verification)
- Run `Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1` - expect 0 findings
- If failures found, fix them before proceeding (especially failures caused by missing modules — these will also fail in CI)
- Re-run checks after fixes to confirm clean

**Definition of Done:**

- [ ] All Pester tests pass in clean `pwsh -NoProfile` session (0 failures)
- [ ] PSScriptAnalyzer reports 0 errors/warnings
- [ ] Both checks verified with fresh run output

**Verify:**

- `pwsh -NoProfile -Command "Invoke-Pester ./Tests -PassThru | Select-Object -Property Result,PassedCount,FailedCount"` - 0 failures (clean session proves CI compatibility)
- `pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1 | Measure-Object | Select-Object -Property Count"` - Count 0

### Task 3: Commit, Push, and Create PR

**Objective:** Commit the CI workflow (and any fixes), push to remote, and create a PR targeting main.

**Dependencies:** Task 2

**Files:**

- Stage: `.github/workflows/ci.yml`, `docs/plans/2026-02-14-cicd-validation-and-pr-merge.md`, any fix files

**Key Decisions / Notes:**

- Commit CI workflow: `feat: add GitHub Actions CI workflow for tests and linting`
- **Stage files explicitly by name** (not `git add .`) to avoid accidentally staging test artifacts or other generated files
- Run `git status --short` before committing to confirm only expected files are staged
- Create PR with descriptive title and summary covering the full feature branch scope
- PR title should cover the overall migration work, not just CI
- Copilot code review: first check availability with `gh pr edit --add-reviewer @copilot`; if command fails (repo doesn't have Copilot access), document in PR comment that Copilot review was not available and skip gracefully
- Use `gh pr create --base main`

**Definition of Done:**

- [ ] All changes committed and pushed (staged explicitly by filename)
- [ ] PR created from `feature/json-config-migration` to `main`
- [ ] PR has descriptive title and summary with test plan
- [ ] Copilot review requested, or documented as unavailable (verify with `gh pr view --json reviewRequests`)

**Verify:**

- `gh pr view --json number,title,state` - PR exists and is open
- `gh pr checks` - CI checks are running or completed

### Task 4: Monitor CI, Fix Failures, Merge, and Clean Up

**Objective:** Monitor CI pipeline, fix any remote CI failures, squash merge the PR, delete the branch, and pull latest main.

**Dependencies:** Task 3

**Files:**

- Modify: Any files that fail in remote CI (TBD)

**Key Decisions / Notes:**

- Use `gh pr checks --watch` to monitor CI status
- If CI fails: read logs with `gh run view <id> --log-failed`, fix, commit, push, re-monitor
- Once CI passes: **approve the PR first** with `gh pr review --approve --body "All CI checks passed: Pester tests green, PSScriptAnalyzer clean. Validated locally and in CI. Approved for merge."`
- After approval: squash merge with `gh pr merge --squash` (do NOT use `--delete-branch` yet)
- After merge: `git checkout main && git pull origin main`
- **Post-merge CI verification:** Check that the merge commit triggers CI on main and passes: `gh run list --branch main --limit 1 --json conclusion --jq '.[].conclusion'` — wait for result
- If post-merge CI fails: revert with `git revert HEAD && git push` and investigate
- After post-merge CI passes: delete remote branch with `gh api -X DELETE repos/BusinessPlus-Community/BPC.DBRefresh/git/refs/heads/feature/json-config-migration` or `git push origin --delete feature/json-config-migration`
- Clean up local feature branch: `git branch -d feature/json-config-migration`
- Verify main is up to date with `git log --oneline -5`

**Definition of Done:**

- [ ] CI pipeline passes on the PR
- [ ] PR approved with descriptive approval message (verify with `gh pr view --json reviewDecision --jq .reviewDecision`)
- [ ] PR squash merged into main
- [ ] Post-merge CI on main passes (verify with `gh run list --branch main --limit 1`)
- [ ] Remote feature branch deleted (after post-merge CI confirmation)
- [ ] Local branch switched to main with latest changes
- [ ] Local feature branch cleaned up
- [ ] `git log --oneline -5` shows squash merge commit on main

**Verify:**

- `gh pr view --json state --jq '.state'` - Returns "MERGED"
- `gh run list --branch main --limit 1 --json conclusion --jq '.[].conclusion'` - Returns "success"
- `git branch --show-current` - Returns "main"
- `git log --oneline -3` - Shows merge commit

## Testing Strategy

- Unit tests: All existing Pester tests run via `Invoke-Pester ./Tests`
- Linting: PSScriptAnalyzer with project settings
- CI validation: GitHub Actions workflow runs both on PR

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| CI runner missing PowerShell modules | Med | Med | Install explicitly with `-ErrorAction Stop -Verbose` and `timeout-minutes: 5` per step to detect PSGallery hangs |
| Tests rely on modules not available in CI | Low | High | Run `pwsh -NoProfile -Command "Invoke-Pester ./Tests"` locally in Task 2 to verify mocks work without dbatools/PSLogging |
| Pester version mismatch in CI | Low | Med | Pin Pester in workflow: `Install-Module -Name Pester -RequiredVersion 5.6.1 -SkipPublisherCheck` |
| CI YAML syntax errors | Low | Low | Validate YAML locally, then verify with `gh workflow view` after push to catch GitHub Actions schema errors |
| Post-merge CI failure on main | Low | High | Delay branch deletion until post-merge CI confirms green; if failed, revert merge commit immediately |

## Open Questions

- None - all requirements clarified.
