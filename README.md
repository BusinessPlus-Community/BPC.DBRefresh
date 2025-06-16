# BusinessPlus Test Environment Refresh

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![CI Pipeline](https://github.com/businessplus-community/BPC.DBRefresh/actions/workflows/ci.yml/badge.svg)](https://github.com/businessplus-community/BPC.DBRefresh/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/businessplus-community/BPC.DBRefresh/branch/main/graph/badge.svg)](https://codecov.io/gh/businessplus-community/BPC.DBRefresh)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/BPC.DBRefresh.svg)](https://www.powershellgallery.com/packages/BPC.DBRefresh)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/businessplus-community/BPC.DBRefresh/graphs/commit-activity)
[![Community](https://img.shields.io/badge/Community-BusinessPlus-orange.svg)](https://github.com/businessplus-community)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/businessplus-community/BPC.DBRefresh/blob/main/CONTRIBUTING.md)

A PowerShell automation script for refreshing BusinessPlus test environments with production database backups.

## Overview

This script automates the process of refreshing data in BusinessPlus test environments by:
- Restoring databases from production backups
- Configuring security and permissions
- Updating environment-specific settings
- Managing services and server reboots

## Prerequisites

### For Traditional Installation
- PowerShell 5.1 or higher (PowerShell 7+ recommended)
- Required PowerShell modules:
  - [PSLogging](https://www.powershellgallery.com/packages/PSLogging) v2.5.2+
  - [dbatools](https://dbatools.io/) v2.1.31+
  - [PsIni](https://www.powershellgallery.com/packages/PsIni) v3.1.2+
- SQL Server access with appropriate permissions
- Access to BusinessPlus environment servers

### For Container Installation (Recommended)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine
- Docker Compose v2.0+
- PowerShell 7+ (for running scripts)
- WSL2 (recommended for Windows users) - see [WSL Setup Guide](docs/WSL-SETUP.md)

### For Development
- All of the above plus:
  - [Pester](https://pester.dev/) v5.7.1+ (for testing)
  - [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) v1.22.0+ (for linting)
  - [PowerShellBuild](https://github.com/psake/PowerShellBuild) v0.6.1+ (for builds)
  - Git for version control

## Installation

### Traditional Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/businessplus-community/BPC.DBRefresh.git
   cd BPC.DBRefresh
   ```

2. Install dependencies:
   ```powershell
   # Install required modules and development dependencies
   ./build.ps1 -Bootstrap
   
   # Or manually install just runtime modules
   Install-Module -Name PSLogging -RequiredVersion 2.5.2 -Scope CurrentUser
   Install-Module -Name dbatools -RequiredVersion 2.1.31 -Scope CurrentUser
   Install-Module -Name PsIni -RequiredVersion 3.1.2 -Scope CurrentUser
   ```

3. Copy and configure the INI file:
   ```powershell
   Copy-Item config\BPC.DBRefresh-sample.ini config\BPC.DBRefresh.ini
   # Edit config\BPC.DBRefresh.ini with your environment settings
   ```

### Container Installation (Recommended)

1. Clone this repository:
   ```bash
   git clone https://github.com/businessplus-community/BPC.DBRefresh.git
   cd BPC.DBRefresh
   ```

2. Copy and configure the environment file:
   ```bash
   cp .env.example .env
   # Edit .env with your SQL Server connection details
   ```

3. Start the development environment:
   ```powershell
   ./scripts/Start-DevEnvironment.ps1
   ```

See [Container Usage Guide](docs/CONTAINER-USAGE.md) for detailed container instructions.

## Project Structure

This project follows PowerShell module best practices:

```
├── BPC.DBRefresh/          # Module source code (root level)
│   ├── BPC.DBRefresh.psd1 # Module manifest
│   ├── BPC.DBRefresh.psm1 # Module file
│   ├── Public/             # Public functions
│   ├── Private/            # Private functions
│   └── Classes/            # PowerShell classes (future use)
├── container/              # Docker container configuration
│   ├── Dockerfile          # Multi-stage build
│   ├── docker-compose.yml  # Main compose file
│   └── README.md           # Container documentation
├── scripts/                # Helper scripts
│   ├── Start-DevEnvironment.ps1
│   ├── Test-LocalCI.ps1
│   └── Test-ContainerSetup.ps1
├── config/                 # Configuration files
├── examples/               # Usage examples
├── tests/                  # Pester tests
├── docs/                   # Documentation
├── build.ps1               # Build script
├── psakeFile.ps1           # Build configuration
└── BPC.DBRefresh.ps1       # Original script (for compatibility)
```

## Usage

### Basic Usage

```powershell
# Traditional method (backward compatible)
.\BPC.DBRefresh.ps1 -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# New module method (recommended)
Import-Module .\BPC.DBRefresh
Invoke-BPERPDatabaseRestore -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>

# Container method
docker compose run --rm bpc-dbrefresh pwsh -Command "Invoke-BPERPDatabaseRestore -BPEnvironment <ENV_NAME> -ifasFilePath <PATH> -syscatFilePath <PATH>"
```

### With All Options

```powershell
.\BPC.DBRefresh.ps1 `
    -BPEnvironment "TEST" `
    -ifasFilePath "\\backup\server\ifas_backup.bak" `
    -syscatFilePath "\\backup\server\syscat_backup.bak" `
    -aspnetFilePath "\\backup\server\aspnet_backup.bak" `
    -testingMode `
    -restoreDashboards
```

### Parameters

- **BPEnvironment** (Required): Target environment name (e.g., TEST, QA, DEV)
- **ifasFilePath** (Required): Path to IFAS database backup file
- **syscatFilePath** (Required): Path to SYSCAT database backup file
- **aspnetFilePath** (Optional): Path to ASPNET database backup file
- **testingMode** (Optional): Enable additional test accounts
- **restoreDashboards** (Optional): Copy dashboard files to environment

## Configuration

The script uses an INI configuration file to define environment-specific settings. See `config\BPC.DBRefresh-sample.ini` for configuration options including:

- SQL Server instances and database names
- Server lists for each environment
- File paths for data, logs, and images
- SMTP settings for notifications
- User permissions and security mappings

## What the Script Does

1. **Pre-flight Checks**: Validates parameters and loads configuration
2. **Service Management**: Stops BusinessPlus services on all environment servers
3. **Database Restoration**:
   - Backs up existing connection configurations
   - Restores databases from provided backup files
   - Reconfigures permissions and security settings
4. **Post-Restore Tasks**:
   - Disables user accounts (except specified manager codes)
   - Updates email addresses to dummy values
   - Disables non-essential workflows
   - Updates system display text with backup date
5. **Environment Restart**: Reboots all servers in the environment
6. **Notification**: Sends email notification upon completion

## Logging

All operations are logged to `BPC.DBRefresh.log` in the script directory. The log includes:
- Timestamp for each operation
- Success/failure status
- Error messages and stack traces
- Database operation details

## Security Considerations

⚠️ **Warning**: This script performs sensitive operations including:
- Database restoration with production data
- User account modifications
- Permission changes
- Server reboots

Ensure you:
- Have proper authorization before running
- Review the configuration file carefully
- Test in a non-production environment first
- Keep backup files and configuration secure

## Development

### Building the Module

```powershell
# Install dependencies and run all build tasks
./build.ps1 -Bootstrap

# Run specific tasks
./build.ps1 -Task Test      # Run tests
./build.ps1 -Task Analyze   # Run PSScriptAnalyzer
./build.ps1 -Task Build     # Build the module
```

### Testing Locally

```powershell
# Run CI tests locally
./scripts/Test-LocalCI.ps1

# Test container setup
./scripts/Test-ContainerSetup.ps1
```

## Troubleshooting

### Common Issues

1. **Module not found errors**: Run `./build.ps1 -Bootstrap` to install dependencies
2. **Access denied errors**: Verify SQL Server and server permissions
3. **Backup file not found**: Check file paths and network connectivity
4. **Email notification failures**: Verify SMTP settings in configuration
5. **Container issues**: See [Container Troubleshooting](docs/CONTAINER-USAGE.md#troubleshooting)

### Debug Mode

For detailed troubleshooting:
- Check the log file at `BPC.DBRefresh.log`
- See [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions:
- Open an [issue](https://github.com/businessplus-community/BPC.DBRefresh/issues)
- Submit a [pull request](https://github.com/businessplus-community/BPC.DBRefresh/pulls)
- Email us at code@bpluscommunity.org

## Acknowledgments

- Built with [dbatools](https://dbatools.io/) for SQL Server operations
- Uses [PSLogging](https://www.powershellgallery.com/packages/PSLogging) for structured logging

## About BusinessPlus Community

The [BusinessPlus Community](https://github.com/businessplus-community) is a collaborative group of K-12 technology professionals sharing tools and knowledge to enhance BusinessPlus ERP/HR/PY system management. Learn more at [bpluscommunity.org](https://bpluscommunity.org).