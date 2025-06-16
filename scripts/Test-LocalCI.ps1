<#
.SYNOPSIS
    Runs CI tests locally using Docker containers
.DESCRIPTION
    This script runs the same tests that would run in GitHub Actions CI/CD
.PARAMETER UseLocalSql
    Use local SQL Server instead of container SQL Server
.PARAMETER KeepContainers
    Don't remove containers after tests complete
.PARAMETER ShowLogs
    Show container logs during execution
.EXAMPLE
    .\Test-LocalCI.ps1
.EXAMPLE
    .\Test-LocalCI.ps1 -UseLocalSql -ShowLogs
#>
[CmdletBinding()]
param(
    [switch]$UseLocalSql,
    [switch]$KeepContainers,
    [switch]$ShowLogs
)

$ErrorActionPreference = 'Stop'

Write-Host "BPC.DBRefresh Local CI Test Runner" -ForegroundColor Green
Write-Host "==================================="

# Check Docker
try {
    $null = docker info 2>&1
} catch {
    Write-Error "Docker is not running. Please start Docker first."
    exit 1
}

# Change to container directory
$containerDir = Join-Path $PSScriptRoot ".." "container"
Push-Location $containerDir

try {
    # Choose compose file
    $composeFile = if ($UseLocalSql -and (Test-Path (Join-Path ".." ".env"))) {
        Write-Host "Using local SQL Server from .env configuration" -ForegroundColor Yellow
        "docker-compose.local-sql.yml"
    } else {
        Write-Host "Using containerized SQL Server for testing" -ForegroundColor Yellow
        "docker-compose.ci.yml"
    }
    
    # Build the container
    Write-Host "`nBuilding container..." -ForegroundColor Cyan
    docker compose -f $composeFile build
    
    # Run the tests
    Write-Host "`nRunning tests..." -ForegroundColor Cyan
    
    $runArgs = @("-f", $composeFile, "up")
    
    if (-not $ShowLogs) {
        $runArgs += "--attach", "bpc-dbrefresh-ci"
    }
    
    if (-not $KeepContainers) {
        $runArgs += "--abort-on-container-exit"
    }
    
    # Run and capture exit code
    docker compose $runArgs
    $exitCode = $LASTEXITCODE
    
    # Get test results if available
    if ($composeFile -eq "docker-compose.ci.yml") {
        Write-Host "`nExtracting test results..." -ForegroundColor Cyan
        
        # Create results directory
        $resultsDir = Join-Path ".." "TestResults"
        if (-not (Test-Path $resultsDir)) {
            New-Item -ItemType Directory -Path $resultsDir | Out-Null
        }
        
        # Copy results from container
        docker cp "bpc-dbrefresh-ci:/workspace/TestResults/." $resultsDir 2>$null
        
        if (Test-Path (Join-Path $resultsDir "test-results.xml")) {
            Write-Host "Test results saved to: $resultsDir" -ForegroundColor Green
        }
    }
    
    # Clean up
    if (-not $KeepContainers) {
        Write-Host "`nCleaning up containers..." -ForegroundColor Yellow
        docker compose -f $composeFile down
    }
    
    # Report results
    if ($exitCode -eq 0) {
        Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "`n✗ Tests failed!" -ForegroundColor Red
        exit $exitCode
    }
    
} catch {
    Write-Error "Test execution failed: $_"
    
    # Try to clean up on error
    if (-not $KeepContainers) {
        docker compose -f $composeFile down 2>$null
    }
    
    exit 1
} finally {
    Pop-Location
}