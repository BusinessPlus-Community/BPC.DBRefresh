# Project: BPC.DBRefresh

**Last Updated:** 2026-01-10

## Overview

PowerShell script that automates the process of refreshing BusinessPlus test environment databases. It handles database restores, security configuration, service management, and notification for SQL Server-based BusinessPlus installations.

## Technology Stack

- **Language:** PowerShell 3.0+
- **Platform:** Windows Server (SQL Server environment)
- **Database:** Microsoft SQL Server
- **Dependencies:**
  - PSLogging (logging framework)
  - dbatools (SQL Server database management)
  - PsIni (INI file parsing)
  - MailKit/MimeKit (email notifications)

## Directory Structure

```
BPC.DBRefresh/
├── hpsBPlusDBRestore.ps1        # Main restore script
├── hpsBPlusDBRestore-sample.ini # Sample configuration file
├── README.md                    # Project documentation
└── LICENSE                      # License file
```

## Key Files

- **Main Script:** `hpsBPlusDBRestore.ps1` - Complete database refresh automation
- **Configuration:** `hpsBPlusDBRestore.ini` (must be created from sample)
- **Sample Config:** `hpsBPlusDBRestore-sample.ini` - Template with all settings documented

## Script Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `BPEnvironment` | Yes | Target environment name (e.g., TEST1) |
| `aspnetFilePath` | No | Path to aspnet database backup |
| `ifasFilePath` | Yes | Path to ifas/bplus database backup |
| `syscatFilePath` | Yes | Path to syscat database backup |
| `testingMode` | No | Enable extra test accounts |
| `restoreDashboards` | No | Copy dashboard files |

## Script Workflow

1. Load required PowerShell modules (PSLogging, dbatools, PsIni)
2. Parse INI configuration for target environment
3. Display configuration summary and prompt for confirmation
4. Stop BusinessPlus services on environment servers
5. Capture existing connection data from databases
6. Restore databases (aspnet, syscat, ifas) with file mapping
7. Restore environment connection information
8. Configure SQL Server security (drop/create users, set permissions)
9. Disable workflows and user accounts (except allowed manager codes)
10. Update NUUPAUSY text and dashboard URL
11. Optionally restore dashboard files
12. Reboot environment servers
13. Send email notification on completion

## Configuration Sections (INI)

- `[sqlServer]` - SQL Server instance per environment
- `[database]` - Main BusinessPlus database name
- `[syscat]` - Syscat database name
- `[aspnet]` - Aspnet database name (optional)
- `[filepathData/Log/Images]` - SQL Server file paths
- `[fileDriveData/Syscat/Aspnet]` - Database file mappings
- `[environmentServers]` - BusinessPlus server list
- `[ipc_daemon]` - IPC service name
- `[SMTP]` - Email notification settings
- `[NUUPAUSY]` - Display text for test indicator
- `[IUSRSource/Destination]` - IUSR account mapping
- `[AdminSource/Destination]` - Admin account mapping
- `[DummyEmail]` - Email address for user accounts
- `[ManagerCode]` - Accounts to keep active
- `[TestingMode]` - Additional accounts for testing
- `[dashboardURL/Files]` - Dashboard configuration

## Development Notes

- Script requires PowerShell 3.0 or higher
- Must run with appropriate SQL Server and Windows permissions
- INI file must be in same directory as script
- Log file created in script directory: `hpsBPlusDBRestore.log`
- Uses MailKit for SMTP (not Send-MailMessage)

## Usage Examples

```powershell
# Basic restore
.\hpsBPlusDBRestore.ps1 -BPEnvironment TEST1 \
  -ifasFilePath "\\backup\ifas.bak" \
  -syscatFilePath "\\backup\syscat.bak"

# With testing mode and dashboard restore
.\hpsBPlusDBRestore.ps1 -BPEnvironment TEST1 \
  -ifasFilePath "\\backup\ifas.bak" \
  -syscatFilePath "\\backup\syscat.bak" \
  -testingMode -restoreDashboards
```

## Additional Context

- Designed for Puyallup School District BusinessPlus environments
- Handles database security transition from production to test
- Disables production workflows to prevent test environment side effects
- Sanitizes email addresses to prevent accidental notifications
