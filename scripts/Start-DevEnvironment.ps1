<#
.SYNOPSIS
    Starts the BPC.DBRefresh development environment using Docker Compose
.DESCRIPTION
    This script starts a containerized development environment with PowerShell and SQL Server
.PARAMETER BuildTests
    Run tests during the Docker build process
.PARAMETER IncludeRunner
    Include the GitHub Actions runner container
.PARAMETER Detached
    Run containers in detached mode
.EXAMPLE
    .\Start-DevEnvironment.ps1
.EXAMPLE
    .\Start-DevEnvironment.ps1 -BuildTests -IncludeRunner
#>
[CmdletBinding()]
param(
    [switch]$BuildTests,
    [switch]$IncludeRunner,
    [switch]$Detached
)

$ErrorActionPreference = 'Stop'

Write-Host "BPC.DBRefresh Development Environment" -ForegroundColor Green
Write-Host "====================================="

# Check Docker
try {
    $null = docker info 2>&1
    $null = docker compose version 2>&1
} catch {
    Write-Error "Docker or Docker Compose is not available. Please install Docker Desktop."
    exit 1
}

# Set build arguments
$env:RUN_TESTS = if ($BuildTests) { "true" } else { "false" }

# Build command arguments
$composeArgs = @("up", "--build")

if ($IncludeRunner) {
    $composeArgs += @("--profile", "runner")
    Write-Host "Including GitHub Actions runner..." -ForegroundColor Yellow
}

if ($Detached) {
    $composeArgs += "-d"
}

# Change to container directory
$containerDir = Join-Path $PSScriptRoot ".." "container"
Push-Location $containerDir

try {
    Write-Host "Starting containers..." -ForegroundColor Yellow
    
    # Determine which compose file to use
    $composeFile = if (Test-Path (Join-Path ".." ".env")) {
        # Check if using local SQL Server
        $envContent = Get-Content (Join-Path ".." ".env") | Where-Object { $_ -match "SQLSERVER_HOST\s*=" }
        if ($envContent -and $envContent -notmatch "SQLSERVER_HOST\s*=\s*(sqlserver|localhost)") {
            "docker-compose.local-sql.yml"
        } else {
            "docker-compose.yml"
        }
    } else {
        "docker-compose.yml"
    }
    
    Write-Host "Using configuration: $composeFile" -ForegroundColor Cyan
    
    # Start the services
    docker compose -f $composeFile $composeArgs
    
    if ($Detached) {
        Write-Host "`nContainers started in detached mode." -ForegroundColor Green
        Write-Host "`nUseful commands:"
        Write-Host "  View logs:        docker compose logs -f"
        Write-Host "  Enter container:  docker compose exec bpc-dbrefresh pwsh"
        Write-Host "  Stop containers:  docker compose down"
        Write-Host "  SQL Server:       localhost:1433 (sa / YourStrong@Passw0rd)"
    } else {
        Write-Host "`nDevelopment environment is running. Press Ctrl+C to stop."
    }
} catch {
    Write-Error "Failed to start development environment: $_"
    exit 1
} finally {
    Pop-Location
}