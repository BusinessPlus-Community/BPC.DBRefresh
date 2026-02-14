## PowerShell Development Standards

**Standards:** Module structure | Pester tests | PSScriptAnalyzer | Comment-based help

### Module Organization

**Public vs Private functions:**
- **Public/** - Exported functions (listed in module manifest FunctionsToExport)
- **Private/** - Internal helper functions (not exported)
- **Resources/** - SQL queries, email templates, static assets

**Naming convention:**
- Use approved PowerShell verbs: `Get-`, `Set-`, `Invoke-`, `Convert-`, etc.
- Singular nouns: `Get-BPlusConfiguration` (not Configurations)
- Check approved verbs: `Get-Verb`

### Comment-Based Help (MANDATORY)

**All exported functions MUST have comment-based help at the beginning:**

```powershell
function Get-BPlusConfiguration {
    <#
    .SYNOPSIS
    Loads and validates JSON configuration for target environment.

    .DESCRIPTION
    Reads the JSON configuration file, validates required fields for the specified
    environment, and returns a configuration object ready for use.

    .PARAMETER ConfigPath
    Path to the JSON configuration file.

    .PARAMETER Environment
    Target environment name (e.g., TEST1, PROD).

    .EXAMPLE
    Get-BPlusConfiguration -ConfigPath "./config.json" -Environment "TEST1"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$Environment
    )
    # Function implementation...
}
```

**Required sections:** SYNOPSIS, DESCRIPTION, PARAMETER (for each param), EXAMPLE

### PSScriptAnalyzer Compliance

**Project uses PSScriptAnalyzerSettings.psd1 with these standards:**

**Brace Style:** OTBS (One True Brace Style)
```powershell
# GOOD - Opening brace on same line
if ($condition) {
    Do-Something
}

# BAD - Opening brace on new line
if ($condition)
{
    Do-Something
}
```

**Indentation:** 4 spaces (no tabs)
```powershell
# GOOD
function Test-Example {
    if ($condition) {
        Write-Output "Nested 4 spaces"
    }
}
```

**No aliases in scripts:**
```powershell
# BAD: foreach, %, ?, where
$items | foreach { $_ }

# GOOD: ForEach-Object
$items | ForEach-Object { $_ }
```

**Avoid Write-Host:** Use Write-Output, Write-Verbose, or Write-Information
```powershell
# BAD
Write-Host "Processing..."

# GOOD
Write-Verbose "Processing..."
Write-Information "Processing..." -InformationAction Continue
```

**Run PSScriptAnalyzer:**
```powershell
Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1
```

### Pester Testing

**Test organization:**
- `Tests/Unit/` - Test individual functions in isolation
- `Tests/Integration/` - Test end-to-end workflows

**Test file naming:** `FunctionName.Tests.ps1`

**Test structure:**
```powershell
BeforeAll {
    # Import module or dot-source function
    . $PSScriptRoot/../../src/BPlusDBRefresh/Private/Get-ScriptPath.ps1
}

Describe 'Get-ScriptPath' {
    Context 'When running interactively' {
        It 'Should return the current directory' {
            $result = Get-ScriptPath
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'When invoked from script' {
        It 'Should return script directory' {
            # Test implementation
        }
    }
}
```

**Run tests:**
```powershell
# All tests
Invoke-Pester ./Tests

# Specific test file
Invoke-Pester ./Tests/Unit/Get-BPlusConfiguration.Tests.ps1

# With coverage
Invoke-Pester ./Tests -CodeCoverage ./src/**/*.ps1
```

### Error Handling

**Use Try/Catch with specific exceptions:**
```powershell
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Error "Configuration file not found: $ConfigPath"
    throw
} catch [System.ArgumentException] {
    Write-Error "Invalid JSON format in configuration file"
    throw
} catch {
    Write-Error "Failed to load configuration: $_"
    throw
}
```

**Always rethrow in functions (let caller decide):**
```powershell
function Get-Something {
    try {
        # Do work
    } catch {
        Write-Error "Failed: $_"
        throw  # Rethrow to caller
    }
}
```

### Parameter Validation

**Use parameter attributes:**
```powershell
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Environment,

    [Parameter()]
    [ValidateScript({ Test-Path $_ })]
    [string]$ConfigPath = "./config.json",

    [Parameter()]
    [ValidateSet('TEST1', 'TEST2', 'PROD')]
    [string]$TargetEnv
)
```

### Module Manifest Best Practices

**Key fields in .psd1:**
- `RootModule` - Points to .psm1
- `ModuleVersion` - Semantic versioning (MAJOR.MINOR.PATCH)
- `FunctionsToExport` - Explicitly list public functions (no wildcards)
- `RequiredModules` - List dependencies
- `CompatiblePSEditions` - Desktop and/or Core

### Verification Checklist

Before completing PowerShell work:
- [ ] Comment-based help on all exported functions
- [ ] PSScriptAnalyzer clean: `Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1`
- [ ] Tests pass: `Invoke-Pester ./Tests`
- [ ] OTBS brace style
- [ ] 4-space indentation
- [ ] No aliases in scripts
- [ ] Approved verbs only

### Quick Reference

| Task | Command |
|------|---------|
| Import module | `Import-Module ./src/BPlusDBRefresh` |
| Run all tests | `Invoke-Pester ./Tests` |
| Run unit tests | `Invoke-Pester ./Tests/Unit` |
| PSScriptAnalyzer | `Invoke-ScriptAnalyzer -Path ./src -Settings ./PSScriptAnalyzerSettings.psd1` |
| Check approved verbs | `Get-Verb` |
| Test single function | `Invoke-Pester ./Tests/Unit/FunctionName.Tests.ps1` |
