# Quick Start: Container Setup for BPC.DBRefresh

This guide will get you running BPC.DBRefresh in a container in under 5 minutes.

## Prerequisites

- Docker Desktop installed and running
- Access to a SQL Server instance (local or remote)
- Database backup files (.bak)
- WSL2 (recommended for Windows) - see [WSL Setup Guide](WSL-SETUP.md)

## Step 1: Clone the Repository

```bash
git clone https://github.com/businessplus-community/BPC.DBRefresh.git
cd BPC.DBRefresh
```

## Step 2: Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit .env with your SQL Server details
# For Windows: notepad .env
# For Linux/Mac: nano .env
```

Key settings to update in `.env`:
```env
SQLSERVER_HOST=your-sql-server     # localhost for local SQL
                                   # WSL users: use host.docker.internal
SQLSERVER_USERNAME=sa              # Your SQL username
SQLSERVER_PASSWORD=YourPassword    # Your SQL password
BACKUP_PATH=/path/to/backups       # Where your .bak files are
```

**WSL Users**: If connecting to SQL Server on Windows, use:
```env
SQLSERVER_HOST=host.docker.internal
```

## Step 3: Start the Container

### Option A: Using PowerShell Script (Recommended)
```powershell
./scripts/Start-DevEnvironment.ps1
```

### Option B: Using Docker Compose Directly
```bash
cd container
docker compose -f docker-compose.local-sql.yml up
```

## Step 4: Run a Database Restore

Once the container is running, you can execute commands:

```powershell
# Enter the container
docker exec -it bpc-dbrefresh pwsh

# Inside the container, run:
Invoke-BPERPDatabaseRestore `
  -BPEnvironment "TEST" `
  -ifasFilePath "/data/backups/ifas.bak" `
  -syscatFilePath "/data/backups/syscat.bak"
```

## Step 5: Run Tests Locally

To run the same tests that run in CI/CD:

```powershell
./scripts/Test-LocalCI.ps1 -UseLocalSql
```

## Common Commands

### View Module Commands
```powershell
docker exec -it bpc-dbrefresh pwsh -Command "Get-Command -Module BPC.DBRefresh"
```

### Check Logs
```bash
docker compose -f container/docker-compose.local-sql.yml logs -f
```

### Stop Containers
```bash
docker compose -f container/docker-compose.local-sql.yml down
```

### Rebuild After Changes
```bash
docker compose -f container/docker-compose.local-sql.yml build --no-cache
```

## Troubleshooting

### SQL Connection Issues
1. Check your `.env` file has correct credentials
2. Ensure SQL Server allows TCP/IP connections
3. Verify firewall allows connection on port 1433

### Permission Errors
- On Linux/Mac, you may need to adjust file permissions:
  ```bash
  chmod +x scripts/*.ps1
  chmod +x scripts/*.sh
  ```

### Container Won't Start
- Check Docker Desktop is running
- Verify no other services are using required ports
- Review logs: `docker compose logs`

## Next Steps

- Read the full [Container Usage Guide](CONTAINER-USAGE.md)
- Review [example scripts](../examples/)
- Configure your [environment INI file](../config/BPC.DBRefresh-sample.ini)

## Getting Help

- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Open an [issue on GitHub](https://github.com/businessplus-community/BPC.DBRefresh/issues)
- Review the [FAQ](FAQ.md)