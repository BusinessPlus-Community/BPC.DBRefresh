function Import-RequiredModule {
    <#
    .SYNOPSIS
        Imports a PowerShell module, installing it if necessary.

    .DESCRIPTION
        Attempts to import a PowerShell module. If the module is not available locally,
        it will attempt to install it from the PowerShell Gallery.

    .PARAMETER ModuleName
        The name of the module to import.

    .PARAMETER MinimumVersion
        Optional minimum version requirement for the module.

    .EXAMPLE
        Import-RequiredModule -ModuleName 'dbatools'

    .OUTPUTS
        None. Throws an error if the module cannot be loaded.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [Parameter()]
        [version]$MinimumVersion
    )

    begin {
        Write-Verbose "$(Get-Date -Format 'G') - Attempting to import PowerShell module: $ModuleName"
    }

    process {
        try {
            # Check if module is already imported
            $importedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
            if ($importedModule) {
                if ($MinimumVersion -and $importedModule.Version -lt $MinimumVersion) {
                    Write-Verbose "Module $ModuleName is imported but version $($importedModule.Version) is below required $MinimumVersion"
                } else {
                    Write-Verbose "Module $ModuleName is already imported (version $($importedModule.Version))"
                    return
                }
            }

            # Check if module is available on disk
            $availableModule = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue |
                Sort-Object -Property Version -Descending |
                Select-Object -First 1

            if ($availableModule) {
                if ($MinimumVersion -and $availableModule.Version -lt $MinimumVersion) {
                    Write-Verbose "Available module version $($availableModule.Version) is below required $MinimumVersion, attempting update"
                } else {
                    Write-Verbose "Importing module $ModuleName from disk (version $($availableModule.Version))"
                    Import-Module -Name $ModuleName -Force -ErrorAction Stop
                    return
                }
            }

            # Module not available locally, try to install from gallery
            Write-Verbose "Module $ModuleName not found locally, searching PowerShell Gallery"

            $galleryModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue
            if ($galleryModule) {
                Write-Verbose "Installing module $ModuleName from PowerShell Gallery (version $($galleryModule.Version))"

                $installParams = @{
                    Name               = $ModuleName
                    Force              = $true
                    Scope              = 'CurrentUser'
                    AllowClobber       = $true
                    SkipPublisherCheck = $true
                    ErrorAction        = 'Stop'
                }

                if ($MinimumVersion) {
                    $installParams['MinimumVersion'] = $MinimumVersion
                }

                Install-Module @installParams
                Import-Module -Name $ModuleName -Force -ErrorAction Stop

                Write-Verbose "Module $ModuleName installed and imported successfully"
                return
            }

            # Module not found anywhere
            $errorMessage = "Module '$ModuleName' not found locally or in PowerShell Gallery"
            throw [System.Management.Automation.ItemNotFoundException]::new($errorMessage)

        } catch {
            $errorMessage = "Failed to import module '$ModuleName': $($_.Exception.Message)"
            throw [System.Management.Automation.RuntimeException]::new($errorMessage, $_.Exception)
        }
    }

    end {
        Write-Verbose "$(Get-Date -Format 'G') - Module import process completed for $ModuleName"
    }
}
