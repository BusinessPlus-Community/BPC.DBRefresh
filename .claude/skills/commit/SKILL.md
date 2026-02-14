---
name: commit
description: Create a conventional commit and push to remote with safety checks
---
# /commit - Safe Git Commit and Push

Create commits with conventional commit format, safety validation, and optional push to remote.

## Safety Checks (MANDATORY)

Before ANY git write operation, perform these checks:

### 1. Branch Protection

```bash
BRANCH=$(git branch --show-current)
```

- **NEVER force push to main/master**
- **Warn if on main/master branch** - Ask user to confirm before committing directly to main

If branch is `main` or `master`:
```
WARNING: You are on the main/master branch.
Committing directly to main is discouraged. Consider creating a feature branch.
Do you want to proceed anyway? (y/N)
```

### 2. Secret Detection

Scan staged files for potential secrets before committing:

```bash
git diff --staged --name-only
```

**Refuse to commit if ANY of these patterns are found:**
- `.env` files (except `.env.example`, `.env.template`)
- Files containing `API_KEY=`, `SECRET=`, `PASSWORD=`, `TOKEN=` with actual values
- `credentials.json`, `secrets.json`, `*.pem`, `*.key` files
- AWS credentials, GCP service accounts, SSH private keys

If secrets detected:
```
BLOCKED: Potential secrets detected in staged files:
- .env (environment file with secrets)
- config/credentials.json (credentials file)

Remove these files from staging:
  git reset HEAD .env config/credentials.json

Or add them to .gitignore if they should never be committed.
```

### 3. Pre-commit Hooks

If pre-commit is available, run it:

```bash
which pre-commit && pre-commit run --files $(git diff --staged --name-only | tr '\n' ' ')
```

If hooks fail:
1. Fix auto-fixable issues (formatting, trailing whitespace)
2. Re-stage modified files: `git add -u`
3. Re-run pre-commit
4. If still failing, show user the errors

## Workflow

### Step 1: Status Check

Show current git state:

```bash
git status --short
git diff --staged --stat
```

**If nothing staged:**
```
No changes staged for commit.

Unstaged changes:
  M src/file.py
  M tests/test_file.py

Would you like to stage these changes? (Options: all, select files, cancel)
```

### Step 2: Safety Validation

Execute ALL safety checks in order:
1. Check current branch (warn if main/master)
2. Scan staged files for secrets
3. Run pre-commit if available

**Stop immediately if any check fails.**

### Step 3: Analyze and Commit

Analyze staged changes to determine commit type:

```bash
git diff --staged
git log --oneline -5  # For context on commit style
```

**Commit Types:**
- `feat:` - New functionality
- `fix:` - Bug fix
- `docs:` - Documentation only
- `refactor:` - Code restructuring without behavior change
- `test:` - Test additions or modifications
- `chore:` - Maintenance, dependencies, tooling

**Create commit with HEREDOC format:**

```bash
git commit -m "$(cat <<'EOF'
<type>: <short description>

<optional body explaining what and why>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Commit message guidelines:**
- First line: `<type>: <imperative description>` (max 72 chars)
- Body: Explain what changed and why (not how)
- Always include Co-Authored-By attribution

### Step 4: Push (Optional)

After successful commit, ask user:

```
Commit created successfully.

Push to remote? (Y/n)
```

**If yes:**

```bash
# Check if upstream exists
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

If no upstream:
```bash
git push -u origin $(git branch --show-current)
```

If upstream exists:
```bash
git push
```

**Never use `--force` on main/master.**

### Step 5: Verify

Show final state:

```bash
git log -1 --oneline
git status
```

Confirm:
- Commit was created with correct message
- Push succeeded (if requested)
- Working directory is clean (or shows remaining unstaged changes)

## Quick Reference

| Step | Command | Purpose |
|------|---------|---------|
| Status | `git status --short` | Check current state |
| Branch | `git branch --show-current` | Verify not on main |
| Secrets | `git diff --staged --name-only` | Scan for secrets |
| Pre-commit | `pre-commit run` | Run hooks |
| Commit | `git commit -m "..."` | Create commit |
| Push | `git push` | Push to remote |
| Verify | `git log -1` | Confirm success |

## Error Recovery

**If commit fails:**
- Check for hook failures
- Verify no merge conflicts
- Ensure staged files exist

**If push fails:**
- Check network connectivity
- Verify remote exists: `git remote -v`
- Check for upstream changes: `git fetch && git status`

**If push rejected (non-fast-forward):**
```
Push rejected. Remote has changes you don't have locally.

Options:
1. Pull and merge: git pull --rebase && git push
2. Review remote changes first: git fetch && git log HEAD..origin/$(git branch --show-current)
```

## Arguments

The skill accepts optional arguments:

- `/commit` - Interactive mode, follows full workflow
- `/commit -m "message"` - Use provided message (still runs safety checks)
- `/commit --no-push` - Skip the push step

ARGUMENTS: $ARGUMENTS
