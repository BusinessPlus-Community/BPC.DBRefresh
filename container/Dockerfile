# Multi-stage build for BPC.DBRefresh PowerShell module
# Stage 1: Build and test
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy module files (from parent directory)
COPY . .

# Install PowerShell dependencies
RUN pwsh -Command "& { \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name Pester -RequiredVersion 5.7.1 -Force; \
    Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.22.0 -Force; \
    Install-Module -Name PowerShellBuild -RequiredVersion 0.6.1 -Force; \
    Install-Module -Name BuildHelpers -RequiredVersion 2.0.16 -Force; \
    Install-Module -Name psake -RequiredVersion 4.9.0 -Force; \
    Install-Module -Name dbatools -RequiredVersion 2.1.31 -Force; \
    Install-Module -Name PSLogging -RequiredVersion 2.2.0 -Force; \
    Install-Module -Name PsIni -RequiredVersion 3.1.2 -Force; \
    }"

# Run tests (optional - can be disabled for faster builds)
ARG RUN_TESTS=false
RUN if [ "$RUN_TESTS" = "true" ]; then \
    pwsh -Command "./build.ps1 -Task Test"; \
    fi

# Build the module
RUN pwsh -Command "./build.ps1 -Task Build"

# Stage 2: Runtime image
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Install runtime dependencies only
RUN pwsh -Command "& { \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name dbatools -RequiredVersion 2.1.31 -Force; \
    Install-Module -Name PSLogging -RequiredVersion 2.2.0 -Force; \
    Install-Module -Name PsIni -RequiredVersion 3.1.2 -Force; \
    }"

# Copy built module from builder stage
COPY --from=builder /workspace/Output/BPC.DBRefresh /opt/microsoft/powershell/7/Modules/BPC.DBRefresh

# Set working directory
WORKDIR /data

# Default command - import module and show available commands
CMD ["pwsh", "-NoExit", "-Command", "Import-Module BPC.DBRefresh; Get-Command -Module BPC.DBRefresh"]