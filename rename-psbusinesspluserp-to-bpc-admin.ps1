# Script to rename PSBusinessPlusERP to BPC.Admin
# Run this script from the PSBusinessPlusERP repository root

Write-Host "This script will help rename PSBusinessPlusERP to BPC.Admin" -ForegroundColor Cyan
Write-Host "Please run these commands from the PSBusinessPlusERP repository root" -ForegroundColor Yellow

# Git commands to rename directories and files
Write-Host "`nStep 1: Rename module directory" -ForegroundColor Green
Write-Host "git mv PSBusinessPlusERP BPC.Admin"

Write-Host "`nStep 2: Rename module files" -ForegroundColor Green
Write-Host "cd BPC.Admin"
Write-Host "git mv PSBusinessPlusERP.psd1 BPC.Admin.psd1"
Write-Host "git mv PSBusinessPlusERP.psm1 BPC.Admin.psm1"
Write-Host "cd .."

Write-Host "`nStep 3: Update Output directory" -ForegroundColor Green
Write-Host "git mv Output/PSBusinessPlusERP Output/BPC.Admin"

Write-Host "`nStep 4: Create PowerShell update script" -ForegroundColor Green
Write-Host @'
# Save this as update-to-bpc-admin.ps1 and run it

# Update all references
$replacements = @{
    'PSBusinessPlusERP' = 'BPC.Admin'
    'PowerSchool BusinessPlus ERP cmdlets' = 'BusinessPlus Community Admin cmdlets'
}

# Update all file types
@('*.md', '*.ps1', '*.psd1', '*.psm1', '*.yml', '*.yaml', '*.json', '*.xml') | ForEach-Object {
    Get-ChildItem -Path . -Filter $_ -Recurse | ForEach-Object {
        if ($_.FullName -notmatch 'update-to-bpc-admin\.ps1') {
            $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $updated = $false
                
                foreach ($old in $replacements.Keys) {
                    if ($content -match $old) {
                        $content = $content -replace $old, $replacements[$old]
                        $updated = $true
                    }
                }
                
                if ($updated) {
                    $content | Set-Content $_.FullName -NoNewline
                    Write-Host "Updated: $($_.FullName)"
                }
            }
        }
    }
}

# Update function prefixes from HelloWorld examples to BPERP
$functionReplacements = @{
    'Get-HelloWorld' = 'Get-BPERPExample'
    'Invoke-BusinessPlusLogin' = 'Invoke-BPERPLogin'
    'New-JoinProp' = 'New-BPERPJoinProperty'
}

Get-ChildItem -Path . -Filter *.ps1 -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $updated = $false
    
    foreach ($old in $functionReplacements.Keys) {
        if ($content -match $old) {
            $content = $content -replace $old, $functionReplacements[$old]
            $updated = $true
        }
    }
    
    if ($updated) {
        $content | Set-Content $_.FullName -NoNewline
        Write-Host "Updated functions in: $($_.FullName)"
    }
}

# Also rename the function files
if (Test-Path "BPC.Admin/Public/Get-HelloWorld.ps1") {
    git mv "BPC.Admin/Public/Get-HelloWorld.ps1" "BPC.Admin/Public/Get-BPERPExample.ps1"
}
if (Test-Path "BPC.Admin/Private/GetHelloWorld.ps1") {
    git mv "BPC.Admin/Private/GetHelloWorld.ps1" "BPC.Admin/Private/GetBPERPExample.ps1"
}
if (Test-Path "BPC.Admin/Public/User/Invoke-BusinessPlusLogin.ps1") {
    git mv "BPC.Admin/Public/User/Invoke-BusinessPlusLogin.ps1" "BPC.Admin/Public/User/Invoke-BPERPLogin.ps1"
}
'@

Write-Host "`nStep 5: Update module manifest specifically" -ForegroundColor Green
Write-Host @'
# In BPC.Admin/BPC.Admin.psd1:
# - Update RootModule to 'BPC.Admin.psm1'
# - Update GUID (generate new one with [guid]::NewGuid())
# - Update Description to mention it's a community module
# - Update CompanyName to 'BusinessPlus Community'
# - Update Tags to include 'BPC', 'Community'
# - Update ProjectUri to 'https://github.com/businessplus-community/BPC.Admin'
'@

Write-Host "`nStep 6: Commit changes" -ForegroundColor Green
Write-Host "git add -A"
Write-Host 'git commit -m "refactor: Rename PSBusinessPlusERP to BPC.Admin for namespace consistency"'

Write-Host "`nStep 7: Update GitHub repository (optional)" -ForegroundColor Green
Write-Host "You may want to rename the GitHub repository from PSBusinessPlusERP to BPC.Admin"
Write-Host "This can be done in GitHub Settings > General > Repository name"
Write-Host "After renaming, update your local remote:"
Write-Host "git remote set-url origin https://github.com/businessplus-community/BPC.Admin.git"

Write-Host "`nDone! The module is now BPC.Admin" -ForegroundColor Green