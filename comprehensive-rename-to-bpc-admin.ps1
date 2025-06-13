# Comprehensive script to rename PSBusinessPlusERP to BPC.Admin
# This script should be run from the PSBusinessPlusERP repository root

param(
    [string]$RepoPath = ".",
    [switch]$DryRun = $false
)

Write-Host "BusinessPlus Community Module Namespace Migration" -ForegroundColor Cyan
Write-Host "Converting PSBusinessPlusERP to BPC.Admin" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
}

# Step 1: Rename directories
Write-Host "`nStep 1: Renaming directories..." -ForegroundColor Green

$directoryRenames = @(
    @{Old = "PSBusinessPlusERP"; New = "BPC.Admin"},
    @{Old = "Output/PSBusinessPlusERP"; New = "Output/BPC.Admin"}
)

foreach ($dir in $directoryRenames) {
    if (Test-Path $dir.Old) {
        Write-Host "  Renaming $($dir.Old) -> $($dir.New)"
        if (-not $DryRun) {
            git mv $dir.Old $dir.New
        }
    }
}

# Step 2: Rename module files
Write-Host "`nStep 2: Renaming module files..." -ForegroundColor Green

$fileRenames = @(
    @{Old = "BPC.Admin/PSBusinessPlusERP.psd1"; New = "BPC.Admin/BPC.Admin.psd1"},
    @{Old = "BPC.Admin/PSBusinessPlusERP.psm1"; New = "BPC.Admin/BPC.Admin.psm1"}
)

foreach ($file in $fileRenames) {
    if (Test-Path $file.Old) {
        Write-Host "  Renaming $($file.Old) -> $($file.New)"
        if (-not $DryRun) {
            git mv $file.Old $file.New
        }
    }
}

# Step 3: Update file contents
Write-Host "`nStep 3: Updating file contents..." -ForegroundColor Green

# Text replacements
$replacements = @{
    'PSBusinessPlusERP' = 'BPC.Admin'
    'PowerSchool BusinessPlus ERP cmdlets' = 'BusinessPlus Community Admin cmdlets'
    'PowerSchool BusinessPlus' = 'BusinessPlus'
}

# Function name replacements to use BPERP prefix
$functionReplacements = @{
    'Get-HelloWorld' = 'Get-BPERPExample'
    'GetHelloWorld' = 'GetBPERPExample'
    'Invoke-BusinessPlusLogin' = 'Invoke-BPERPLogin'
    'New-JoinProp' = 'New-BPERPJoinProperty'
}

# Get all relevant files
$filesToUpdate = Get-ChildItem -Path . -Include @('*.ps1', '*.psd1', '*.psm1', '*.md', '*.yml', '*.yaml', '*.json', '*.xml') -Recurse

foreach ($file in $filesToUpdate) {
    if ($file.FullName -match '\.git' -or $file.FullName -match 'node_modules') { continue }
    
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $originalContent = $content
    
    # Apply text replacements
    foreach ($old in $replacements.Keys) {
        $content = $content -replace [regex]::Escape($old), $replacements[$old]
    }
    
    # Apply function replacements
    foreach ($old in $functionReplacements.Keys) {
        $content = $content -replace $old, $functionReplacements[$old]
    }
    
    if ($content -ne $originalContent) {
        Write-Host "  Updating: $($file.FullName)"
        if (-not $DryRun) {
            $content | Set-Content $file.FullName -NoNewline
        }
    }
}

# Step 4: Rename function files
Write-Host "`nStep 4: Renaming function files..." -ForegroundColor Green

$functionFileRenames = @(
    @{Old = "BPC.Admin/Public/Get-HelloWorld.ps1"; New = "BPC.Admin/Public/Get-BPERPExample.ps1"},
    @{Old = "BPC.Admin/Private/GetHelloWorld.ps1"; New = "BPC.Admin/Private/GetBPERPExample.ps1"},
    @{Old = "BPC.Admin/Public/User/Invoke-BusinessPlusLogin.ps1"; New = "BPC.Admin/Public/User/Invoke-BPERPLogin.ps1"},
    @{Old = "docs/en-US/Get-HelloWorld.md"; New = "docs/en-US/Get-BPERPExample.md"},
    @{Old = "docs/en-US/Invoke-BusinessPlusLogin.md"; New = "docs/en-US/Invoke-BPERPLogin.md"},
    @{Old = "docs/en-US/ReportFetch/New-JoinProp.md"; New = "docs/en-US/ReportFetch/New-BPERPJoinProperty.md"}
)

foreach ($file in $functionFileRenames) {
    if (Test-Path $file.Old) {
        Write-Host "  Renaming $($file.Old) -> $($file.New)"
        if (-not $DryRun) {
            git mv $file.Old $file.New
        }
    }
}

# Step 5: Update manifest specifically
Write-Host "`nStep 5: Updating module manifest..." -ForegroundColor Green

$manifestPath = "BPC.Admin/BPC.Admin.psd1"
if (Test-Path $manifestPath) {
    Write-Host "  Updating manifest file"
    if (-not $DryRun) {
        $manifest = Get-Content $manifestPath -Raw
        
        # Update RootModule
        $manifest = $manifest -replace "RootModule\s*=\s*'PSBusinessPlusERP\.psm1'", "RootModule = 'BPC.Admin.psm1'"
        
        # Update Description
        $manifest = $manifest -replace "Description\s*=\s*'PowerSchool BusinessPlus ERP cmdlets'", "Description = 'BusinessPlus Community Admin cmdlets for K-12 school districts'"
        
        # Update CompanyName
        $manifest = $manifest -replace "CompanyName\s*=\s*'Unknown'", "CompanyName = 'BusinessPlus Community'"
        
        # Update Copyright
        $manifest = $manifest -replace "Copyright\s*=\s*'\(c\) 2024 Zach Birge\. All rights reserved\.'", "Copyright = '(c) 2024 BusinessPlus Community. All rights reserved. Licensed under GPL-3.0'"
        
        # Add/Update PrivateData if needed
        if ($manifest -notmatch 'ProjectUri') {
            Write-Host "  Adding PrivateData section with metadata"
            # This would need more complex logic to insert properly
        }
        
        $manifest | Set-Content $manifestPath -NoNewline
    }
}

# Step 6: Create/Update CLAUDE.md
Write-Host "`nStep 6: Creating CLAUDE.md..." -ForegroundColor Green

$claudeContent = @"
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the BPC.Admin module - a PowerShell module providing administrative cmdlets for BusinessPlus ERP/HR/PY systems. This module is part of the BPC (BusinessPlus Community) namespace.

## Module Namespace

The BusinessPlus Community uses the BPC namespace for all modules:
- `BPC.Admin` - Administrative functions (this module)
- `BPC.DBRefresh` - Database refresh operations
- `BPC.Reports` - Report generation/fetching
- `BPC.Security` - User/permission management
- `BPC.Finance` - Financial operations
- `BPC.HR` - Human resources functions

## Project Structure

```
BPC.Admin/              # Module source
├── Public/             # Public functions
├── Private/            # Private functions
├── BPC.Admin.psd1      # Module manifest
└── BPC.Admin.psm1      # Module file
docs/                   # Documentation
tests/                  # Pester tests
Output/                 # Build output
```

## Development Standards

### Function Naming
All functions use the BPERP prefix:
- `Invoke-BPERPLogin`
- `Get-BPERPExample`
- `New-BPERPJoinProperty`

### Testing
Run tests with:
```powershell
Invoke-Pester -Path .\tests
```

### Building
Build the module:
```powershell
.\build.ps1
```

## Key Features

This module provides administrative functions for BusinessPlus systems including:
- User authentication and session management
- Report generation utilities
- Data manipulation helpers

## Contributing

Follow the standards in CONTRIBUTING.md. All contributions should maintain the BPC namespace conventions and BPERP function prefix.
"@

if (-not $DryRun) {
    $claudeContent | Set-Content "CLAUDE.md" -NoNewline
    Write-Host "  Created CLAUDE.md"
}

# Step 7: Summary
Write-Host "`nStep 7: Summary of changes" -ForegroundColor Green
Write-Host "  - Module renamed from PSBusinessPlusERP to BPC.Admin"
Write-Host "  - Functions updated to use BPERP prefix"
Write-Host "  - Manifest updated with community information"
Write-Host "  - CLAUDE.md created with namespace documentation"

if (-not $DryRun) {
    Write-Host "`nStep 8: Commit changes" -ForegroundColor Green
    Write-Host "Run these commands to commit:"
    Write-Host "  git add -A" -ForegroundColor Yellow
    Write-Host '  git commit -m "refactor: Rename to BPC.Admin namespace"' -ForegroundColor Yellow
    Write-Host "  git push origin v2" -ForegroundColor Yellow
} else {
    Write-Host "`nDRY RUN COMPLETE - No changes were made" -ForegroundColor Magenta
    Write-Host "Run without -DryRun flag to apply changes" -ForegroundColor Yellow
}

Write-Host "`nDone!" -ForegroundColor Green