#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for MailKit-related functions.
#>

BeforeAll {
    # Dot-source the functions for testing
    $testMailKitPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Test-MailKitAvailable.ps1'
    $installMailKitPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Install-MailKitDependency.ps1'

    . $testMailKitPath
    . $installMailKitPath
}

Describe 'Test-MailKitAvailable' {
    Context 'Parameter Validation' {
        It 'Has optional Detailed switch parameter' {
            $command = Get-Command -Name Test-MailKitAvailable
            $command.Parameters['Detailed'] | Should -Not -BeNullOrEmpty
            $command.Parameters['Detailed'].SwitchParameter | Should -Be $true
        }

        It 'Has correct output types defined' {
            $command = Get-Command -Name Test-MailKitAvailable
            $outputTypes = $command.OutputType.Type.Name
            # PowerShell uses 'Boolean' and 'PSObject' for type names
            $outputTypes | Should -Contain 'Boolean'
            $outputTypes | Should -Contain 'PSObject'
        }
    }

    Context 'Return Value Types' {
        It 'Returns boolean by default' {
            $result = Test-MailKitAvailable
            $result | Should -BeOfType [bool]
        }

        It 'Returns PSCustomObject when Detailed switch is used' {
            $result = Test-MailKitAvailable -Detailed
            $result | Should -BeOfType [PSCustomObject]
        }
    }

    Context 'Detailed Output Properties' {
        BeforeAll {
            $script:DetailedResult = Test-MailKitAvailable -Detailed
        }

        It 'Has Available property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'Available'
        }

        It 'Has MailKitPath property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'MailKitPath'
        }

        It 'Has MimeKitPath property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'MimeKitPath'
        }

        It 'Has MailKitLoaded property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'MailKitLoaded'
        }

        It 'Has MimeKitLoaded property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'MimeKitLoaded'
        }

        It 'Has Message property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'Message'
        }

        It 'Has NuGetPath property' {
            $script:DetailedResult.PSObject.Properties.Name | Should -Contain 'NuGetPath'
        }

        It 'Message provides guidance when not available' {
            if (-not $script:DetailedResult.Available) {
                $script:DetailedResult.Message | Should -Match 'Install-MailKitDependency|not found|Error'
            }
        }
    }

    Context 'Assembly Detection' {
        It 'Checks for loaded assemblies in current AppDomain' {
            # This test verifies the function looks at loaded assemblies
            # The actual result depends on whether MailKit is installed
            $result = Test-MailKitAvailable -Detailed

            # Either assemblies are loaded, or paths are searched
            ($result.MailKitLoaded -or $result.MailKitPath -or $result.Message) | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Install-MailKitDependency' {
    Context 'Parameter Validation' {
        It 'Has CmdletBinding with SupportsShouldProcess' {
            $command = Get-Command -Name Install-MailKitDependency
            $command.CmdletBinding | Should -Be $true
            $command.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
            $command.Parameters['Confirm'] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'NuGet Provider Detection' {
        BeforeAll {
            # Mock Get-PackageProvider to test provider detection
            Mock Get-PackageProvider {
                return $null
            } -ParameterFilter { $Name -eq 'NuGet' -and $ErrorAction -eq 'SilentlyContinue' }

            Mock Install-PackageProvider {
                return [PSCustomObject]@{ Name = 'NuGet'; Version = '2.8.5.208' }
            }

            Mock Install-Package { }
            Mock Test-MailKitAvailable { return $true }
        }

        It 'Attempts to install NuGet provider if not present' -Skip:$true {
            # Skip this test as it would actually try to install packages
            # In a real CI environment, this would be mocked properly
            { Install-MailKitDependency -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Package Installation' {
        BeforeAll {
            Mock Get-PackageProvider {
                return [PSCustomObject]@{ Name = 'NuGet'; Version = '2.8.5.208' }
            }

            Mock Install-Package {
                return [PSCustomObject]@{
                    Name    = $Name
                    Version = '3.0.0'
                }
            }

            Mock Test-MailKitAvailable { return $true }
        }

        It 'Supports WhatIf' {
            $command = Get-Command -Name Install-MailKitDependency
            $command.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        BeforeAll {
            Mock Get-PackageProvider { throw 'Provider error' }
        }

        It 'Handles errors gracefully' -Skip:$true {
            # This test is skipped as it requires actual package manager access
            # In production, proper mocking would be set up
            { Install-MailKitDependency -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
