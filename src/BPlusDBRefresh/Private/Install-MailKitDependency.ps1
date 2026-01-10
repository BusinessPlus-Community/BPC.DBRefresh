function Install-MailKitDependency {
    <#
    .SYNOPSIS
        Installs MailKit and MimeKit NuGet packages for email functionality.

    .DESCRIPTION
        Installs MailKit and its dependencies (MimeKit, BouncyCastle, System.Buffers)
        via NuGet package provider. This is required because Send-MailMessage is
        deprecated per Microsoft DE0005.

    .PARAMETER Force
        Bypasses confirmation prompts and forces installation.

    .PARAMETER Scope
        Specifies the installation scope. Default is CurrentUser.

    .EXAMPLE
        Install-MailKitDependency

        Installs MailKit with confirmation prompt.

    .EXAMPLE
        Install-MailKitDependency -Force

        Installs MailKit without confirmation.

    .OUTPUTS
        PSCustomObject with installation results.

    .NOTES
        Requires administrative privileges for AllUsers scope.
        Send-MailMessage is deprecated: https://github.com/dotnet/platform-compat/blob/master/docs/DE0005.md
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser'
    )

    $result = [PSCustomObject]@{
        Success          = $false
        PackagesInstalled = @()
        NuGetPath        = $null
        Message          = ''
        Errors           = @()
    }

    try {
        # Check if already available
        $availability = Test-MailKitAvailable -Detailed
        if ($availability.Available) {
            $result.Success = $true
            $result.NuGetPath = $availability.NuGetPath
            $result.Message = 'MailKit is already installed'
            return $result
        }

        # Ensure NuGet provider is available
        Write-Verbose 'Checking for NuGet package provider'
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue

        if (-not $nugetProvider) {
            Write-Verbose 'Installing NuGet package provider'

            if ($PSCmdlet.ShouldProcess('NuGet Provider', 'Install')) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope $Scope -ErrorAction Stop
            }
        }

        # Register NuGet source if not present
        $nugetSource = Get-PackageSource -Name 'NuGet' -ErrorAction SilentlyContinue
        if (-not $nugetSource) {
            Write-Verbose 'Registering NuGet package source'

            if ($PSCmdlet.ShouldProcess('NuGet Source', 'Register')) {
                Register-PackageSource -Name NuGet -Location 'https://www.nuget.org/api/v2' -ProviderName NuGet -Force -ErrorAction Stop
            }
        }

        # Packages to install (in dependency order)
        $packages = @(
            @{ Name = 'System.Buffers'; MinVersion = '4.5.0' },
            @{ Name = 'Portable.BouncyCastle'; MinVersion = '1.8.0' },
            @{ Name = 'MimeKit'; MinVersion = '2.15.0' },
            @{ Name = 'MailKit'; MinVersion = '2.15.0' }
        )

        foreach ($package in $packages) {
            $packageName = $package.Name
            Write-Verbose "Installing package: $packageName"

            if ($PSCmdlet.ShouldProcess($packageName, 'Install NuGet package')) {
                try {
                    $installParams = @{
                        Name            = $packageName
                        ProviderName    = 'NuGet'
                        Scope           = $Scope
                        Force           = $true
                        SkipDependencies = $false
                        ErrorAction     = 'Stop'
                    }

                    if ($package.MinVersion) {
                        $installParams['MinimumVersion'] = $package.MinVersion
                    }

                    $installedPackage = Install-Package @installParams
                    $result.PackagesInstalled += $installedPackage.Name
                    Write-Verbose "Successfully installed $packageName"

                } catch {
                    $errorMsg = "Failed to install $packageName : $($_.Exception.Message)"
                    $result.Errors += $errorMsg
                    Write-Warning $errorMsg
                }
            }
        }

        # Verify installation
        $verifyResult = Test-MailKitAvailable -Detailed
        if ($verifyResult.Available) {
            $result.Success = $true
            $result.NuGetPath = $verifyResult.NuGetPath
            $result.Message = "Successfully installed MailKit and dependencies"
        } else {
            $result.Message = "Installation completed but verification failed: $($verifyResult.Message)"
        }

    } catch {
        $result.Errors += $_.Exception.Message
        $result.Message = "Failed to install MailKit dependencies: $($_.Exception.Message)"
    }

    $result
}
