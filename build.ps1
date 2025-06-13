<#
.SYNOPSIS
    Build script for BPlusDBRestore PowerShell module

.DESCRIPTION
    This script performs build tasks including:
    - Running PSScriptAnalyzer
    - Running Pester tests
    - Building module
    - Creating release package

.PARAMETER Task
    The build task to run. Default is 'Build'.
    Available tasks: Analyze, Test, Build, Package, Clean, All

.EXAMPLE
    .\build.ps1 -Task All
    Runs all build tasks

.EXAMPLE
    .\build.ps1 -Task Test
    Runs only the Pester tests
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Analyze', 'Test', 'Build', 'Package', 'Clean', 'All')]
    [string]$Task = 'Build'
)

#region Helper Functions
function Write-BuildHeader {
    param([string]$Message)
    Write-Host "`n==[ $Message ]==" -ForegroundColor Cyan
}

function Write-BuildSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-BuildError {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-BuildInfo {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}
#endregion

#region Build Tasks
function Invoke-Analyze {
    Write-BuildHeader "Running PSScriptAnalyzer"
    
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-BuildError "PSScriptAnalyzer not installed. Installing..."
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }
    
    $analyzerParams = @{
        Path = @(
            "$PSScriptRoot\src"
            "$PSScriptRoot\examples"
            "$PSScriptRoot\tests"
            "$PSScriptRoot\hpsBPlusDBRestore.ps1"
        )
        Settings = "$PSScriptRoot\PSScriptAnalyzerSettings.psd1"
        Recurse = $true
        ReportSummary = $true
    }
    
    $results = Invoke-ScriptAnalyzer @analyzerParams
    
    if ($results) {
        Write-BuildError "PSScriptAnalyzer found $($results.Count) issues:"
        $results | Format-Table -AutoSize
        return $false
    }
    else {
        Write-BuildSuccess "No PSScriptAnalyzer issues found"
        return $true
    }
}

function Invoke-Test {
    Write-BuildHeader "Running Pester Tests"
    
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-BuildError "Pester not installed. Installing..."
        Install-Module -Name Pester -Force -Scope CurrentUser -MinimumVersion 5.0
    }
    
    $pesterParams = @{
        Path = "$PSScriptRoot\tests"
        OutputFormat = 'Detailed'
        PassThru = $true
    }
    
    $results = Invoke-Pester @pesterParams
    
    if ($results.FailedCount -gt 0) {
        Write-BuildError "$($results.FailedCount) tests failed"
        return $false
    }
    else {
        Write-BuildSuccess "All $($results.PassedCount) tests passed"
        return $true
    }
}

function Invoke-Build {
    Write-BuildHeader "Building Module"
    
    $modulePath = "$PSScriptRoot\src\BPlusDBRestore"
    $moduleFile = Join-Path $modulePath "BPlusDBRestore.psm1"
    
    # Create module file if it doesn't exist
    if (-not (Test-Path $moduleFile)) {
        Write-BuildInfo "Creating module file..."
        
        # For now, we'll create a wrapper that dot-sources the original script
        # In a full conversion, we'd refactor the script into proper functions
        $moduleContent = @'
#Requires -Version 5.1
#Requires -Modules PSLogging, dbatools, PsIni

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile "$ModuleRoot\BPlusDBRestore.psd1").ModuleVersion

# Import private functions
$Private = Get-ChildItem -Path "$ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($import in $Private) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import private function $($import.FullName): $_"
    }
}

# Import public functions
$Public = Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue
foreach ($import in $Public) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import public function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
'@
        
        Set-Content -Path $moduleFile -Value $moduleContent -Encoding UTF8
        Write-BuildSuccess "Module file created"
    }
    
    # Test module import
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-BuildSuccess "Module imports successfully"
        return $true
    }
    catch {
        Write-BuildError "Failed to import module: $_"
        return $false
    }
}

function Invoke-Package {
    Write-BuildHeader "Creating Release Package"
    
    $version = (Import-PowerShellDataFile "$PSScriptRoot\src\BPlusDBRestore\BPlusDBRestore.psd1").ModuleVersion
    $packageDir = "$PSScriptRoot\releases\v$version"
    
    # Create release directory
    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    
    # Copy files
    Write-BuildInfo "Copying module files..."
    Copy-Item -Path "$PSScriptRoot\src\BPlusDBRestore" -Destination "$packageDir\" -Recurse
    
    Write-BuildInfo "Copying documentation..."
    Copy-Item -Path "$PSScriptRoot\README.md" -Destination "$packageDir\"
    Copy-Item -Path "$PSScriptRoot\LICENSE" -Destination "$packageDir\"
    Copy-Item -Path "$PSScriptRoot\CHANGELOG.md" -Destination "$packageDir\"
    
    Write-BuildInfo "Copying examples..."
    Copy-Item -Path "$PSScriptRoot\examples" -Destination "$packageDir\" -Recurse
    
    Write-BuildInfo "Copying configuration..."
    Copy-Item -Path "$PSScriptRoot\config" -Destination "$packageDir\" -Recurse
    
    # Create zip
    $zipPath = "$PSScriptRoot\releases\BPlusDBRestore-v$version.zip"
    Compress-Archive -Path "$packageDir\*" -DestinationPath $zipPath -Force
    
    Write-BuildSuccess "Package created: $zipPath"
    return $true
}

function Invoke-Clean {
    Write-BuildHeader "Cleaning Build Artifacts"
    
    $itemsToRemove = @(
        "$PSScriptRoot\releases"
        "$PSScriptRoot\TestResults.xml"
        "$PSScriptRoot\coverage.xml"
    )
    
    foreach ($item in $itemsToRemove) {
        if (Test-Path $item) {
            Remove-Item $item -Recurse -Force
            Write-BuildInfo "Removed: $item"
        }
    }
    
    Write-BuildSuccess "Clean completed"
    return $true
}
#endregion

#region Main
$ErrorActionPreference = 'Stop'

Write-Host "BPlusDBRestore Build Script" -ForegroundColor Magenta
Write-Host "Task: $Task" -ForegroundColor Gray

$success = $true

switch ($Task) {
    'Analyze' {
        $success = Invoke-Analyze
    }
    'Test' {
        $success = Invoke-Test
    }
    'Build' {
        $success = Invoke-Build
    }
    'Package' {
        $success = Invoke-Build
        if ($success) {
            $success = Invoke-Package
        }
    }
    'Clean' {
        $success = Invoke-Clean
    }
    'All' {
        $success = Invoke-Clean
        if ($success) { $success = Invoke-Analyze }
        if ($success) { $success = Invoke-Test }
        if ($success) { $success = Invoke-Build }
        if ($success) { $success = Invoke-Package }
    }
}

if ($success) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}
#endregion