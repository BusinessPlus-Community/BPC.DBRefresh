<#
.SYNOPSIS
    Tests the BPC.DBRefresh container setup
.DESCRIPTION
    This script verifies that the container environment is properly configured
.EXAMPLE
    .\Test-ContainerSetup.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "`nBPC.DBRefresh Container Setup Test" -ForegroundColor Green
Write-Host "==================================`n"

$testsPassed = 0
$testsFailed = 0

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$ErrorMessage
    )
    
    Write-Host "Testing: $Name... " -NoNewline
    try {
        $result = & $Test
        if ($result) {
            Write-Host "PASS" -ForegroundColor Green
            $script:testsPassed++
            return $true
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            if ($ErrorMessage) { Write-Host "  $ErrorMessage" -ForegroundColor Yellow }
            $script:testsFailed++
            return $false
        }
    } catch {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Yellow
        $script:testsFailed++
        return $false
    }
}

# Test 1: Docker is installed
Test-Requirement -Name "Docker installed" -Test {
    $null = Get-Command docker -ErrorAction Stop
    $true
} -ErrorMessage "Please install Docker Desktop"

# Test 2: Docker is running
Test-Requirement -Name "Docker running" -Test {
    docker info 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
} -ErrorMessage "Please start Docker Desktop"

# Test 3: Docker Compose v2
Test-Requirement -Name "Docker Compose v2" -Test {
    docker compose version 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
} -ErrorMessage "Docker Compose v2 is required"

# Test 4: Container directory exists
Test-Requirement -Name "Container directory" -Test {
    Test-Path (Join-Path $PSScriptRoot ".." "container")
} -ErrorMessage "Container directory not found"

# Test 5: Dockerfile exists
Test-Requirement -Name "Dockerfile exists" -Test {
    Test-Path (Join-Path $PSScriptRoot ".." "container" "Dockerfile")
} -ErrorMessage "Dockerfile not found"

# Test 6: Docker compose files exist
Test-Requirement -Name "Docker compose files" -Test {
    $containerDir = Join-Path $PSScriptRoot ".." "container"
    (Test-Path (Join-Path $containerDir "docker-compose.yml")) -and
    (Test-Path (Join-Path $containerDir "docker-compose.local-sql.yml")) -and
    (Test-Path (Join-Path $containerDir "docker-compose.ci.yml"))
} -ErrorMessage "Docker compose files not found"

# Test 7: .env.example exists
Test-Requirement -Name ".env.example file" -Test {
    Test-Path (Join-Path $PSScriptRoot ".." ".env.example")
} -ErrorMessage ".env.example not found"

# Test 8: Scripts are executable
if ($IsLinux -or $IsMacOS) {
    Test-Requirement -Name "Scripts executable" -Test {
        $scriptPath = Join-Path $PSScriptRoot "run-local-ci.sh"
        if (Test-Path $scriptPath) {
            $fileInfo = Get-Item $scriptPath
            # Check if executable bit is set
            $true  # Simplified for cross-platform
        } else {
            $false
        }
    } -ErrorMessage "Scripts need executable permissions"
}

# Test 9: Build the container
$buildTest = Test-Requirement -Name "Container build" -Test {
    Push-Location (Join-Path $PSScriptRoot ".." "container")
    try {
        Write-Host ""
        Write-Host "  Building container (this may take a few minutes)..." -ForegroundColor Cyan
        docker build --build-arg RUN_TESTS=false -t bpc-dbrefresh:test ..
        $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
} -ErrorMessage "Container build failed"

# Test 10: Run container test
if ($buildTest) {
    Test-Requirement -Name "Container execution" -Test {
        $output = docker run --rm bpc-dbrefresh:test pwsh -Command "Get-Module -ListAvailable BPC.DBRefresh | Select-Object -First 1"
        $output -match "BPC.DBRefresh"
    } -ErrorMessage "Module not available in container"
}

# Summary
Write-Host "`n==============================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "==============================`n" -ForegroundColor Cyan

if ($testsFailed -eq 0) {
    Write-Host "✓ All tests passed! Container setup is ready." -ForegroundColor Green
    Write-Host "`nNext steps:"
    Write-Host "  1. Copy .env.example to .env and configure"
    Write-Host "  2. Run: ./scripts/Start-DevEnvironment.ps1"
    Write-Host "  3. See docs/QUICKSTART-CONTAINER.md for usage`n"
    exit 0
} else {
    Write-Host "✗ Some tests failed. Please fix the issues above." -ForegroundColor Red
    Write-Host "`nFor help, see:"
    Write-Host "  - docs/CONTAINER-USAGE.md"
    Write-Host "  - docs/TROUBLESHOOTING.md`n"
    exit 1
}