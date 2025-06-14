<#
.SYNOPSIS
    Installs required PowerShell modules for BPC.DBRefresh

.DESCRIPTION
    This script installs all required PowerShell modules needed to build, test, and run
    the BPC.DBRefresh module. It can be used standalone or integrated with build processes.

.PARAMETER Scope
    The installation scope for modules. Default is 'CurrentUser'.
    Valid values: 'CurrentUser', 'AllUsers'

.PARAMETER Force
    Force installation of modules even if they already exist

.PARAMETER NuGetBootstrap
    Bootstrap NuGet package provider if not already installed

.EXAMPLE
    .\Requirements.ps1
    Installs all required modules for the current user

.EXAMPLE
    .\Requirements.ps1 -Scope AllUsers -Force
    Force installs all modules for all users (requires admin rights)
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$NuGetBootstrap
)

#region Module Requirements
$RequiredModules = @(
    # Module dependencies (Required for runtime)
    @{
        Name = 'PSLogging'
        MinimumVersion = '2.2.0'
        SkipPublisherCheck = $true
    },
    @{
        Name = 'dbatools'
        MinimumVersion = '1.0.0'
        SkipPublisherCheck = $true
    },
    @{
        Name = 'PsIni'
        MinimumVersion = '3.1.2'
        SkipPublisherCheck = $true
    }
)

$DevelopmentModules = @(
    # Build and test dependencies
    @{
        Name = 'Pester'
        MinimumVersion = '5.0.0'
        SkipPublisherCheck = $true
    },
    @{
        Name = 'PSScriptAnalyzer'
        MinimumVersion = '1.19.1'
        SkipPublisherCheck = $false
    },
    @{
        Name = 'psake'
        MinimumVersion = '4.9.0'
        SkipPublisherCheck = $false
    },
    @{
        Name = 'BuildHelpers'
        MinimumVersion = '2.0.16'
        SkipPublisherCheck = $false
    },
    @{
        Name = 'PowerShellBuild'
        MinimumVersion = '0.6.1'
        SkipPublisherCheck = $false
    }
)

# Combine all modules
$AllModules = $RequiredModules + $DevelopmentModules
#endregion

#region Functions
function Write-RequirementInfo {
    param([string]$Message)
    Write-Host "[Requirements] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-RequirementSuccess {
    param([string]$Message)
    Write-Host "[✓] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-RequirementWarning {
    param([string]$Message)
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-RequirementError {
    param([string]$Message)
    Write-Host "[✗] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}
#endregion

#region Main Script
Write-RequirementInfo "Starting module dependency installation..."
Write-RequirementInfo "Installation scope: $Scope"

# Bootstrap NuGet if requested
if ($NuGetBootstrap) {
    Write-RequirementInfo "Bootstrapping NuGet package provider..."
    try {
        $null = Get-PackageProvider -Name NuGet -ForceBootstrap -ErrorAction Stop
        Write-RequirementSuccess "NuGet package provider ready"
    }
    catch {
        Write-RequirementError "Failed to bootstrap NuGet: $_"
        exit 1
    }
}

# Ensure PSGallery is trusted
$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($psGallery.InstallationPolicy -ne 'Trusted') {
    Write-RequirementInfo "Setting PSGallery as trusted repository..."
    try {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        Write-RequirementSuccess "PSGallery is now trusted"
    }
    catch {
        Write-RequirementWarning "Could not set PSGallery as trusted: $_"
    }
}

# Install each module
$failedModules = @()
foreach ($module in $AllModules) {
    Write-RequirementInfo "Checking module: $($module.Name) (>= $($module.MinimumVersion))"
    
    # Check if module is already installed
    $installedModule = Get-Module -Name $module.Name -ListAvailable | 
        Where-Object { $_.Version -ge [version]$module.MinimumVersion } |
        Sort-Object Version -Descending |
        Select-Object -First 1
    
    if ($installedModule -and -not $Force) {
        Write-RequirementSuccess "$($module.Name) v$($installedModule.Version) is already installed"
        continue
    }
    
    # Install or update module
    try {
        $installParams = @{
            Name = $module.Name
            MinimumVersion = $module.MinimumVersion
            Scope = $Scope
            Force = $Force
            AllowClobber = $true
            ErrorAction = 'Stop'
        }
        
        if ($module.SkipPublisherCheck) {
            $installParams['SkipPublisherCheck'] = $true
        }
        
        if ($Force -and $installedModule) {
            Write-RequirementInfo "Force updating $($module.Name)..."
        }
        else {
            Write-RequirementInfo "Installing $($module.Name)..."
        }
        
        Install-Module @installParams
        
        # Verify installation
        $verifyModule = Get-Module -Name $module.Name -ListAvailable | 
            Where-Object { $_.Version -ge [version]$module.MinimumVersion } |
            Sort-Object Version -Descending |
            Select-Object -First 1
            
        if ($verifyModule) {
            Write-RequirementSuccess "$($module.Name) v$($verifyModule.Version) installed successfully"
        }
        else {
            throw "Module verification failed"
        }
    }
    catch {
        Write-RequirementError "Failed to install $($module.Name): $_"
        $failedModules += $module.Name
    }
}

# Summary
Write-Host "`n" -NoNewline
if ($failedModules.Count -eq 0) {
    Write-RequirementSuccess "All modules installed successfully!"
    exit 0
}
else {
    Write-RequirementError "Failed to install the following modules:"
    $failedModules | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
#endregion