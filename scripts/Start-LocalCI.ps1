<#
.SYNOPSIS
    Runs GitHub Actions workflows locally using act
.DESCRIPTION
    This script simulates the CI pipeline locally without consuming GitHub Actions minutes
.PARAMETER Workflow
    Specify workflow file to run (default: all workflows)
.PARAMETER Platform
    Platform to test on (default: ubuntu-latest)
.PARAMETER Event
    GitHub event to simulate (default: push)
.EXAMPLE
    .\Start-LocalCI.ps1
.EXAMPLE
    .\Start-LocalCI.ps1 -Workflow .github/workflows/ci.yml -Platform windows-latest
#>
[CmdletBinding()]
param(
    [string]$Workflow,
    [string]$Platform = "ubuntu-latest",
    [string]$Event = "push"
)

Write-Host "BPC.DBRefresh Local CI Runner" -ForegroundColor Green
Write-Host "================================"

# Check if act is installed
$actPath = Get-Command act -ErrorAction SilentlyContinue
if (-not $actPath) {
    Write-Host "Installing act..." -ForegroundColor Yellow
    
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5) {
        # Windows installation
        Invoke-WebRequest -Uri "https://github.com/nektos/act/releases/latest/download/act_Windows_x86_64.zip" -OutFile "$env:TEMP\act.zip"
        Expand-Archive -Path "$env:TEMP\act.zip" -DestinationPath "$env:TEMP\act" -Force
        $actExe = "$env:TEMP\act\act.exe"
    } else {
        # Linux/macOS installation
        bash -c "curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        $actExe = "act"
    }
} else {
    $actExe = "act"
}

# Check if Docker is running
try {
    $null = docker info 2>&1
} catch {
    Write-Error "Docker is not running. Please start Docker first."
    exit 1
}

# Create act configuration if it doesn't exist
$actrcPath = Join-Path $PSScriptRoot ".." ".actrc"
if (-not (Test-Path $actrcPath)) {
    Write-Host "Creating .actrc configuration..." -ForegroundColor Yellow
    @"
# Default image for ubuntu-latest
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04

# Windows images (note: these are Linux containers simulating Windows)
-P windows-latest=catthehacker/ubuntu:act-latest
-P windows-2022=catthehacker/ubuntu:act-latest
-P windows-2019=catthehacker/ubuntu:act-latest

# macOS images (note: these are Linux containers simulating macOS)
-P macos-latest=catthehacker/ubuntu:act-latest
-P macos-12=catthehacker/ubuntu:act-latest
-P macos-11=catthehacker/ubuntu:act-latest

# Default runner
--container-architecture linux/amd64
"@ | Set-Content -Path $actrcPath
}

# Build act command
$actArgs = @($Event, "-P", "$Platform=$Platform")

if ($Workflow) {
    Write-Host "Running workflow: $Workflow" -ForegroundColor Green
    $actArgs += @("-W", $Workflow)
} else {
    Write-Host "Running all workflows..." -ForegroundColor Green
}

Write-Host "Platform: $Platform"
Write-Host "Event: $Event"

# Run act
$originalLocation = Get-Location
try {
    Set-Location (Join-Path $PSScriptRoot "..")
    & $actExe $actArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Local CI run completed successfully!" -ForegroundColor Green
    } else {
        Write-Error "✗ Local CI run failed!"
        exit 1
    }
} finally {
    Set-Location $originalLocation
}