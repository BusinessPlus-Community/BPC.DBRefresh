# WSL Setup Guide for BPC.DBRefresh

This guide explains how to use BPC.DBRefresh with Windows Subsystem for Linux (WSL).

## Overview

BPC.DBRefresh fully supports WSL and is actually recommended for better Docker performance. The solution works seamlessly across Windows (PowerShell/WSL), Linux, and macOS.

## Prerequisites

### 1. WSL2 Installation
Ensure you have WSL2 installed:
```powershell
# In Windows PowerShell (Admin)
wsl --install

# Check WSL version
wsl -l -v
```

### 2. Docker Desktop Configuration
Configure Docker Desktop for WSL2:
1. Open Docker Desktop → Settings
2. General → Enable "Use WSL 2 based engine" ✓
3. Resources → WSL Integration → Enable integration with your distro ✓
4. Apply & Restart

### 3. PowerShell Core in WSL
Install PowerShell Core in your WSL distribution:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell

# Verify installation
pwsh --version
```

## Running from WSL

### Method 1: Using PowerShell Scripts (Recommended)

```bash
# Navigate to your project (adjust path as needed)
cd /mnt/d/repos/BPC.DBRefresh

# Copy and configure environment
cp .env.example .env
nano .env  # Edit with your SQL Server details

# Run using PowerShell script
pwsh ./scripts/Start-DevEnvironment.ps1

# Or run tests
pwsh ./scripts/Test-LocalCI.ps1 -UseLocalSql
```

### Method 2: Using Docker Compose Directly

```bash
# Navigate to container directory
cd /mnt/d/repos/BPC.DBRefresh/container

# Start with local SQL Server
docker compose -f docker-compose.local-sql.yml up

# Or run CI tests
docker compose -f docker-compose.ci.yml up
```

## SQL Server Connection Configuration

### Connecting to Windows SQL Server from WSL

When connecting to SQL Server running on Windows from WSL containers:

#### Option 1: Using host.docker.internal (Recommended)
```env
# In your .env file
SQLSERVER_HOST=host.docker.internal
SQLSERVER_PORT=1433
SQLSERVER_USERNAME=sa
SQLSERVER_PASSWORD=YourPassword
```

#### Option 2: Using Windows Host IP
```bash
# Find your Windows IP from WSL
ip route | grep default | awk '{print $3}'

# Or use PowerShell
powershell.exe -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like '*WSL*'} | Select-Object -ExpandProperty IPAddress"
```

Then use this IP in your `.env`:
```env
SQLSERVER_HOST=172.x.x.x  # Your Windows host IP
```

#### Option 3: Using localhost with Host Network
The default configuration uses host network mode:
```yaml
# In docker-compose.local-sql.yml
network_mode: "host"  # Allows localhost access
```

### SQL Server Configuration Requirements

1. **Enable TCP/IP Protocol**:
   - Open SQL Server Configuration Manager
   - SQL Server Network Configuration → Protocols
   - Enable TCP/IP
   - Restart SQL Server

2. **Configure Firewall**:
   ```powershell
   # In Windows PowerShell (Admin)
   New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
   ```

3. **Enable Mixed Mode Authentication** (if using SQL auth):
   - SQL Server Management Studio → Server Properties
   - Security → SQL Server and Windows Authentication mode

## Common WSL Commands

### File Operations
```bash
# Your Windows drives are mounted under /mnt
cd /mnt/c/Users/YourName/Documents
cd /mnt/d/repos/BPC.DBRefresh

# Copy files between Windows and WSL
cp /mnt/c/path/to/file.bak ./backups/

# Edit files
nano .env
# or
code .env  # Opens in VSCode
```

### Permission Management
```bash
# Fix script permissions
chmod +x scripts/*.sh
chmod +x scripts/*.ps1

# Fix ownership issues
sudo chown -R $(whoami):$(whoami) .
```

### Docker Commands
```bash
# Check Docker is working
docker --version
docker compose version

# View running containers
docker ps

# View logs
docker compose logs -f bpc-dbrefresh

# Enter container
docker exec -it bpc-dbrefresh pwsh
```

## Troubleshooting

### Issue: Cannot connect to SQL Server

1. **Test connectivity from WSL**:
   ```bash
   # Test if port is open
   pwsh -Command "Test-NetConnection -ComputerName host.docker.internal -Port 1433"
   
   # Or using netcat
   nc -zv host.docker.internal 1433
   ```

2. **Check SQL Server is listening**:
   ```powershell
   # In Windows PowerShell
   Get-NetTCPConnection -LocalPort 1433
   ```

3. **Verify SQL Server authentication**:
   ```sql
   -- In SSMS
   SELECT auth_scheme FROM sys.dm_exec_connections WHERE session_id = @@SPID;
   ```

### Issue: Docker command not found

```bash
# Ensure Docker is available in WSL
which docker

# If not found, check Docker Desktop WSL integration
# Docker Desktop → Settings → Resources → WSL Integration
```

### Issue: Permission denied errors

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Logout and login again, or run
newgrp docker
```

### Issue: Slow file operations

WSL2 file performance is best when working within the Linux filesystem:
```bash
# Copy project to WSL filesystem for better performance
cp -r /mnt/d/repos/BPC.DBRefresh ~/projects/
cd ~/projects/BPC.DBRefresh
```

## VSCode Integration

This project is already configured for WSL:

1. **Default Terminal**: WSL (Debian) is set as default
2. **Remote Development**: Install "Remote - WSL" extension
3. **Open in WSL**: 
   ```bash
   # From WSL
   code /mnt/d/repos/BPC.DBRefresh
   ```

## Performance Tips

1. **Use WSL2** (not WSL1) for better Docker performance
2. **Store files in WSL filesystem** for faster I/O when possible
3. **Allocate sufficient memory** to WSL2:
   ```powershell
   # Create/edit %USERPROFILE%\.wslconfig
   [wsl2]
   memory=8GB
   processors=4
   ```

4. **Use Docker BuildKit**:
   ```bash
   export DOCKER_BUILDKIT=1
   ```

## Best Practices

1. **Development Workflow**:
   - Edit files in VSCode with WSL Remote
   - Run containers from WSL terminal
   - Use PowerShell Core (pwsh) for scripts

2. **Path Handling**:
   - Use forward slashes in paths
   - Use `/mnt/d/` for D: drive access
   - Avoid spaces in paths when possible

3. **Line Endings**:
   - Configure Git for proper line endings:
   ```bash
   git config --global core.autocrlf input
   ```

## Quick Reference

```bash
# Start development environment
pwsh ./scripts/Start-DevEnvironment.ps1

# Run tests
pwsh ./scripts/Test-LocalCI.ps1 -UseLocalSql

# Test container setup
pwsh ./scripts/Test-ContainerSetup.ps1

# Enter container
docker exec -it bpc-dbrefresh pwsh

# Run specific command
docker compose run --rm bpc-dbrefresh pwsh -Command "Get-Module BPC.DBRefresh"

# Clean up
docker compose down
```

## Additional Resources

- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Desktop WSL 2 backend](https://docs.docker.com/desktop/windows/wsl/)
- [PowerShell in WSL](https://docs.microsoft.com/en-us/powershell/scripting/install/install-ubuntu)
- [VSCode Remote - WSL](https://code.visualstudio.com/docs/remote/wsl)