# Container Usage Guide for BPC.DBRefresh

This guide explains how to run BPC.DBRefresh in containers and use local GitHub Actions runners.

> **Note**: For WSL (Windows Subsystem for Linux) users, see the [WSL Setup Guide](WSL-SETUP.md) for specific configuration and troubleshooting.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose v2.0+
- PowerShell 7+ (for PowerShell scripts)
- Git

## Quick Start

### 1. Development Environment

Start the full development environment with PowerShell and SQL Server:

```bash
# Using PowerShell
./scripts/Start-DevEnvironment.ps1

# Or using Docker Compose directly
docker compose up --build
```

This starts:
- **bpc-dbrefresh**: PowerShell container with the module installed
- **sqlserver**: SQL Server 2022 for testing database operations

### 2. Running CI Locally

Test GitHub Actions workflows without using cloud runners:

```bash
# Install act and run all workflows
./scripts/run-local-ci.sh

# Run specific workflow
./scripts/run-local-ci.sh -w .github/workflows/ci.yml

# Run on specific platform
./scripts/run-local-ci.sh -p windows-latest

# Using PowerShell
./scripts/Start-LocalCI.ps1 -Workflow .github/workflows/ci.yml
```

## Container Architecture

### Production Container

The Dockerfile uses a multi-stage build:

1. **Builder Stage**: Installs all dependencies, optionally runs tests, builds module
2. **Runtime Stage**: Minimal image with only runtime dependencies

Build with tests:
```bash
docker build --build-arg RUN_TESTS=true -t bpc-dbrefresh:latest .
```

### Development Containers

The `docker-compose.yml` provides:

```yaml
services:
  bpc-dbrefresh:    # Main module container
  sqlserver:        # SQL Server for testing
  github-runner:    # Optional self-hosted runner
```

## Usage Examples

### Interactive PowerShell Session

```bash
# Start containers
docker compose up -d

# Enter PowerShell in container
docker compose exec bpc-dbrefresh pwsh

# In PowerShell:
Import-Module BPC.DBRefresh
Get-Command -Module BPC.DBRefresh
```

### Running Module Commands

```bash
# Copy your config file into container
docker cp config/MyEnvironment.ini bpc-dbrefresh:/data/config/

# Run database restore
docker compose exec bpc-dbrefresh pwsh -Command "
  Invoke-BPERPDatabaseRestore -BPEnvironment Test `
    -ifasFilePath /data/backups/ifas.bak `
    -syscatFilePath /data/backups/syscat.bak
"
```

### Using with SQL Server

The included SQL Server container:
- Listens on `localhost:1433`
- Username: `sa`
- Password: `YourStrong@Passw0rd`
- Backup directory: `/var/opt/mssql/backup` (mapped to `db-backups` volume)

```powershell
# Test SQL connectivity from module container
docker compose exec bpc-dbrefresh pwsh -Command "
  Import-Module dbatools
  Test-DbaConnection -SqlInstance sqlserver -SqlCredential (Get-Credential sa)
"
```

## Self-Hosted GitHub Runner

To use a self-hosted runner in a container:

1. Get a runner token from GitHub:
   - Go to Settings → Actions → Runners → New self-hosted runner
   - Copy the token

2. Start with runner:
   ```bash
   export RUNNER_TOKEN="your-token-here"
   docker compose --profile runner up
   ```

3. The runner will appear in your GitHub repository

## Production Deployment

### Kubernetes Example

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: bpc-dbrefresh-config
data:
  Test.ini: |
    [GlobalSettings]
    LogPath = /data/logs
    # ... rest of config

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bpc-dbrefresh
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bpc-dbrefresh
  template:
    metadata:
      labels:
        app: bpc-dbrefresh
    spec:
      containers:
      - name: bpc-dbrefresh
        image: bpc-dbrefresh:latest
        volumeMounts:
        - name: config
          mountPath: /data/config
        - name: backups
          mountPath: /data/backups
      volumes:
      - name: config
        configMap:
          name: bpc-dbrefresh-config
      - name: backups
        persistentVolumeClaim:
          claimName: backup-pvc
```

### Running as a Job

```bash
# Create a job to run database refresh
docker run --rm \
  -v ./config:/data/config:ro \
  -v ./backups:/data/backups:ro \
  bpc-dbrefresh:latest \
  pwsh -Command "Invoke-BPERPDatabaseRestore -BPEnvironment Test -ifasFilePath /data/backups/ifas.bak -syscatFilePath /data/backups/syscat.bak"
```

## Troubleshooting

### Common Issues

1. **Module not found**
   ```bash
   # Rebuild the container
   docker compose build --no-cache bpc-dbrefresh
   ```

2. **SQL Server connection issues**
   ```bash
   # Check SQL Server health
   docker compose ps
   docker compose logs sqlserver
   ```

3. **Permission issues**
   ```bash
   # Run with appropriate user
   docker run --user "$(id -u):$(id -g)" bpc-dbrefresh:latest
   ```

### Debugging

```bash
# View container logs
docker compose logs -f bpc-dbrefresh

# Enter container for debugging
docker compose exec bpc-dbrefresh bash

# Check module installation
docker compose exec bpc-dbrefresh pwsh -Command "Get-Module -ListAvailable BPC.DBRefresh"
```

## CI/CD Integration

### GitHub Actions with Container

```yaml
name: Container CI
on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: bpc-dbrefresh:latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          pwsh -Command "
            Import-Module BPC.DBRefresh
            Invoke-Pester -Path /workspace/tests
          "
```

### GitLab CI

```yaml
test:
  image: bpc-dbrefresh:latest
  script:
    - pwsh -Command "Import-Module BPC.DBRefresh; Invoke-Pester"
```

## Security Considerations

1. **Never commit sensitive data** in config files
2. Use **secrets** for database passwords
3. Run containers with **least privilege**
4. Regularly **update base images**
5. Scan images for vulnerabilities:
   ```bash
   docker scout cves bpc-dbrefresh:latest
   ```

## Performance Tips

1. Use **multi-stage builds** to reduce image size
2. **Cache PowerShell modules** in separate layer
3. Mount configs as **read-only** volumes
4. Use **specific version tags** for reproducibility

## Next Steps

- Customize the Dockerfile for your environment
- Set up automated builds in your CI/CD pipeline
- Configure monitoring and logging
- Implement health checks for production use