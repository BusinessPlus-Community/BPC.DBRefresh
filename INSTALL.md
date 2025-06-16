# Installation Guide

## Prerequisites

Before installing the BusinessPlus Test Environment Refresh module, ensure you have:

1. **PowerShell 5.1 or higher**

   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **Administrator privileges** (for system-wide installation)

3. **Internet connectivity** (for downloading dependencies)

## Installation Methods

### Method 1: PowerShell Gallery (Recommended)

```powershell
# Install for current user
Install-Module -Name BPC.DBRefresh -Scope CurrentUser

# Install system-wide (requires admin)
Install-Module -Name BPC.DBRefresh -Scope AllUsers
```

### Method 2: From GitHub Release

1. Download the latest release from [GitHub Releases](https://github.com/businessplus-community/BPC.DBRefresh/releases)

2. Extract the ZIP file

3. Import the module:

   ```powershell
   Import-Module "C:\path\to\extracted\BPC.DBRefresh"
   ```

### Method 3: From Source

1. Clone the repository:

   ```powershell
   git clone https://github.com/businessplus-community/BPC.DBRefresh.git
   cd BPC.DBRefresh
   ```

2. Install dependencies using the build script:

   ```powershell
   ./build.ps1 -Bootstrap
   ```

3. Import the module:

   ```powershell
   Import-Module .\BPC.DBRefresh -Force
   ```

### Method 4: Development Installation

For contributors and developers:

1. Fork and clone the repository
2. Install all development dependencies:

   ```powershell
   ./build.ps1 -Bootstrap
   ```

3. Create a symbolic link to your PowerShell modules directory (optional):

   ```powershell
   $modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\BPC.DBRefresh"
   New-Item -ItemType SymbolicLink -Path $modulePath -Target ".\BPC.DBRefresh"
   ```

### Method 5: Container Installation

For containerized environments:

1. Install Docker Desktop or Docker Engine
2. Clone the repository
3. Copy and configure environment:

   ```powershell
   cp .env.example .env
   # Edit .env with SQL Server details
   ```

4. Start the container:

   ```powershell
   ./scripts/Start-DevEnvironment.ps1
   ```

## Dependency Installation

The module requires these PowerShell modules:

```powershell
# Set PSGallery as trusted (optional but recommended)
Set-PSRepository PSGallery -InstallationPolicy Trusted

# Install all dependencies
Install-Module -Name PSLogging -RequiredVersion 2.5.2
Install-Module -Name dbatools -RequiredVersion 2.1.31
Install-Module -Name PsIni -RequiredVersion 3.1.2

# Or use the build script (recommended)
./build.ps1 -Bootstrap
```

## Configuration Setup

1. Copy the sample configuration:

   ```powershell
   Copy-Item ".\config\BPC.DBRefresh-sample.ini" ".\config\BPC.DBRefresh.ini"
   ```

2. Edit the configuration file with your environment details:

   ```powershell
   notepad ".\config\BPC.DBRefresh.ini"
   ```

## Verification

Verify the installation:

```powershell
# Check if module is available
Get-Module -ListAvailable BPC.DBRefresh

# Import and check version
Import-Module BPC.DBRefresh
Get-Module BPC.DBRefresh

# List available commands
Get-Command -Module BPC.DBRefresh

# Get help
Get-Help Invoke-BPERPDatabaseRestore -Detailed
```

## Offline Installation

For environments without internet access:

1. On a connected machine, save the modules:

   ```powershell
   # Save the module and its dependencies
   Save-Module -Name PSLogging -RequiredVersion 2.5.2 -Path C:\OfflineModules
   Save-Module -Name dbatools -RequiredVersion 2.1.31 -Path C:\OfflineModules
   Save-Module -Name PsIni -RequiredVersion 3.1.2 -Path C:\OfflineModules
   
   # Also save development dependencies if needed
   Save-Module -Name Pester -RequiredVersion 5.7.1 -Path C:\OfflineModules
   Save-Module -Name PSScriptAnalyzer -RequiredVersion 1.22.0 -Path C:\OfflineModules
   Save-Module -Name PowerShellBuild -RequiredVersion 0.6.1 -Path C:\OfflineModules
   ```

2. Copy the `C:\OfflineModules` folder to the offline machine

3. Install from the local folder:

   ```powershell
   $modulePath = "$env:ProgramFiles\PowerShell\Modules"
   Copy-Item -Path "C:\OfflineModules\*" -Destination $modulePath -Recurse
   ```

## Troubleshooting Installation

### Module not found

```powershell
# Check module paths
$env:PSModulePath -split ';'

# Add custom path if needed
$env:PSModulePath += ";C:\CustomModulePath"
```

### Permission denied

```powershell
# Run PowerShell as Administrator
# Or install to user scope
Install-Module BPC.DBRefresh -Scope CurrentUser
```

### Dependency conflicts

```powershell
# Force update dependencies
Update-Module PSLogging, dbatools, PsIni -Force
```

## Next Steps

After installation:

1. Review the [README](README.md) for usage instructions
2. Configure your environment settings
3. Test with a non-production environment first
4. Check [FAQ](docs/FAQ.md) for common questions

## Uninstallation

To remove the module:

```powershell
# Remove module
Uninstall-Module -Name BPC.DBRefresh

# Remove dependencies (if not used by other modules)
Uninstall-Module -Name PSLogging, dbatools, PsIni

# Remove configuration files manually
Remove-Item ".\config\BPC.DBRefresh.ini"
```
