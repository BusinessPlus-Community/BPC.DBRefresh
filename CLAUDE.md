# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PowerShell automation script for refreshing BusinessPlus test environments with production database backups. The script handles database restoration, security configuration, and environment-specific settings.

## Project Structure

```
src/BPlusDBRestore/    # PowerShell module
config/                # Configuration files
examples/              # Usage examples
tests/                 # Pester tests
hpsBPlusDBRestore.ps1  # Original script (compatibility)
```

## Commands

### Running the Script

```powershell
# Traditional method (backward compatible)
.\hpsBPlusDBRestore.ps1 -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# Module method (recommended)
Import-Module .\src\BPlusDBRestore
Restore-BPlusDatabase -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# Build and test
.\build.ps1 -Task All
```

Parameters:

- `BPEnvironment`: Target environment name (required)
- `ifasFilePath`: Path to IFAS database backup file (required)
- `syscatFilePath`: Path to SYSCAT database backup file (required)
- `aspnetFilePath`: Path to ASPNET database backup file (optional)
- `testingMode`: Enable additional test accounts (optional)
- `restoreDashboards`: Copy dashboard files to environment (optional)

### PowerShell Module Requirements

The script requires these PowerShell modules:

- PSLogging
- dbatools
- PsIni

## Architecture

### Configuration Structure

The script uses INI files for environment configuration (`config/hpsBPlusDBRestore-sample.ini`):

- SQL Server instances and database mappings
- Server lists per environment
- File paths for data, logs, and images
- SMTP settings for notifications
- User permissions and security mappings

### Workflow Sequence

1. **Initialization**: Loads modules, parses INI configuration
2. **Service Management**: Stops BusinessPlus services across environment servers
3. **Database Operations**:
   - Backs up existing connection configurations
   - Restores databases from provided backup files
   - Reconfigures permissions and security settings
4. **Post-Restore Tasks**:
   - Disables user accounts (preserves manager codes)
   - Updates email addresses to dummy values
   - Disables non-essential workflows
   - Updates NUUPAUSY display text
5. **Environment Restart**: Reboots all servers
6. **Notification**: Sends completion email

### Key Technical Details

- **Logging**: All operations logged to `hpsBPlusDBRestore.log`
- **Security**: Contains operations that modify database permissions and user access
- **Dependencies**: Requires SQL Server access and appropriate permissions
- **Email**: Uses MailKit assemblies for SMTP notifications
