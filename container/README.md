# Container Configuration for BPC.DBRefresh

This directory contains all Docker-related files for running BPC.DBRefresh in containers.

> **WSL Users**: This solution fully supports WSL! See the [WSL Setup Guide](../docs/WSL-SETUP.md) for specific instructions.

## Quick Start

### Using Local SQL Server

1. Copy `.env.example` to `.env` in the project root:
   ```bash
   cp ../.env.example ../.env
   ```

2. Edit `../.env` with your local SQL Server details:
   ```env
   SQLSERVER_HOST=localhost
   SQLSERVER_USERNAME=sa
   SQLSERVER_PASSWORD=YourPassword
   ```

3. Run with local SQL Server:
   ```bash
   docker compose -f docker-compose.local-sql.yml up
   ```

### Using Container SQL Server

Run with included SQL Server:
```bash
docker compose -f docker-compose.yml --profile with-sql up
```

### CI Testing

Run automated tests:
```bash
docker compose -f docker-compose.ci.yml up --build
```

## Files

- `Dockerfile` - Multi-stage build for the module
- `docker-compose.yml` - Main compose file with all services
- `docker-compose.local-sql.yml` - Configuration for local SQL Server
- `docker-compose.ci.yml` - CI/CD testing configuration
- `.dockerignore` - Files to exclude from Docker context

## Configuration Profiles

### Default Profile
- Uses local SQL Server (via host network)
- Mounts local config and backup directories
- Interactive PowerShell session

### with-sql Profile
- Includes SQL Server container
- Isolated network
- Good for testing without local SQL

### CI Profile
- Runs all tests automatically
- Generates test results and coverage
- Exits with appropriate code

## Environment Variables

Key variables from `.env`:
- `SQLSERVER_HOST` - SQL Server hostname
- `SQLSERVER_PORT` - SQL Server port (default: 1433)
- `SQLSERVER_USERNAME` - SQL username
- `SQLSERVER_PASSWORD` - SQL password
- `BACKUP_PATH` - Path to backup files
- `LOG_PATH` - Path for log files

## Usage Examples

### Interactive Development
```bash
# Start container with local SQL
cd container
docker compose -f docker-compose.local-sql.yml up

# In another terminal, execute commands
docker exec -it bpc-dbrefresh pwsh
```

### Run Specific Command
```bash
docker compose -f docker-compose.local-sql.yml run --rm bpc-dbrefresh pwsh -Command "
  Invoke-BPERPDatabaseRestore -BPEnvironment Test \
    -ifasFilePath /data/backups/ifas.bak \
    -syscatFilePath /data/backups/syscat.bak
"
```

### CI Testing
```bash
# Run tests and get exit code
docker compose -f docker-compose.ci.yml up --build --exit-code-from bpc-dbrefresh-ci
```