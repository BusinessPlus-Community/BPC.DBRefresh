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
        Repository = 'PSGallery'
    },
    @{
        Name = 'dbatools'
        MinimumVersion = '1.0.0'
        Repository = 'PSGallery'
    },
    @{
        Name = 'PsIni'
        MinimumVersion = '3.1.2'
        Repository = 'PSGallery'
    }
)

$DevelopmentModules = @(
    # Build and test dependencies
    @{
        Name = 'Pester'
        MinimumVersion = '5.0.0'
        Repository = 'PSGallery'
    },
    @{
        Name = 'PSScriptAnalyzer'
        MinimumVersion = '1.19.1'
        Repository = 'PSGallery'
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
Write-RequirementInfo "Checking PSGallery trust status..."
try {
    $psGallery = Get-PSRepository -Name PSGallery -ErrorAction Stop
    if ($psGallery.InstallationPolicy -ne 'Trusted') {
        Write-RequirementInfo "Setting PSGallery as trusted repository..."
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        Write-RequirementSuccess "PSGallery is now trusted"
    }
    else {
        Write-RequirementSuccess "PSGallery is already trusted"
    }
}
catch {
    Write-RequirementWarning "Could not verify PSGallery status: $_"
}

# Install each module
$failedModules = @()
foreach ($module in $AllModules) {
    Write-RequirementInfo "Checking module: $($module.Name) (>= $($module.MinimumVersion))"
    
    # Check if module is already installed
    $installedModule = Get-Module -Name $module.Name -ListAvailable -ErrorAction SilentlyContinue | 
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
            Repository = $module.Repository
            Scope = $Scope
            Force = $true
            AllowClobber = $true
            ErrorAction = 'Stop'
        }
        
        # Remove SkipPublisherCheck for now to avoid issues
        
        if ($Force -and $installedModule) {
            Write-RequirementInfo "Force updating $($module.Name)..."
        }
        else {
            Write-RequirementInfo "Installing $($module.Name)..."
        }
        
        # Try installation with retries for network issues
        $retries = 3
        $installed = $false
        
        for ($i = 1; $i -le $retries; $i++) {
            try {
                Install-Module @installParams
                $installed = $true
                break
            }
            catch {
                if ($i -eq $retries) {
                    throw
                }
                Write-RequirementWarning "Attempt $i failed, retrying..."
                Start-Sleep -Seconds 2
            }
        }
        
        if (-not $installed) {
            throw "Failed after $retries attempts"
        }
        
        # Verify installation
        $verifyModule = Get-Module -Name $module.Name -ListAvailable -ErrorAction SilentlyContinue | 
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
        
        # Try alternative installation methods for problematic modules
        if ($module.Name -eq 'PsIni') {
            Write-RequirementInfo "Trying alternative installation for PsIni..."
            try {
                # Sometimes specifying exact version helps
                Install-Module -Name PsIni -RequiredVersion 3.1.3 -Repository PSGallery -Scope $Scope -Force -AllowClobber -ErrorAction Stop
                Write-RequirementSuccess "PsIni installed via alternative method"
                $failedModules = $failedModules | Where-Object { $_ -ne 'PsIni' }
            }
            catch {
                Write-RequirementError "Alternative installation also failed: $_"
            }
        }
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