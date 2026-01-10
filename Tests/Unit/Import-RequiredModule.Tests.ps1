#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Import-RequiredModule function.
#>

BeforeAll {
    # Dot-source the function directly for testing
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Import-RequiredModule.ps1'
    . $functionPath
}

Describe 'Import-RequiredModule' {
    Context 'Parameter Validation' {
        It 'Has mandatory ModuleName parameter' {
            $command = Get-Command -Name Import-RequiredModule
            $command.Parameters['ModuleName'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has optional MinimumVersion parameter' {
            $command = Get-Command -Name Import-RequiredModule
            $command.Parameters['MinimumVersion'] | Should -Not -BeNullOrEmpty
        }

        It 'ModuleName validates as not null or empty' {
            { Import-RequiredModule -ModuleName '' } | Should -Throw
        }
    }

    Context 'Module Already Imported' {
        BeforeAll {
            # Mock Get-Module to simulate an already-imported module
            Mock Get-Module {
                if ($ListAvailable) { return $null }
                return [PSCustomObject]@{
                    Name    = 'TestModule'
                    Version = [version]'1.0.0'
                }
            } -ParameterFilter { $Name -eq 'TestModule' }
        }

        It 'Returns early if module is already imported' {
            { Import-RequiredModule -ModuleName 'TestModule' -Verbose } | Should -Not -Throw
            Should -Invoke -CommandName Get-Module -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestModule' -and -not $ListAvailable }
        }
    }

    Context 'Module Available on Disk' {
        BeforeAll {
            # Mock Get-Module to simulate module available but not imported
            Mock Get-Module {
                if ($ListAvailable) {
                    return [PSCustomObject]@{
                        Name    = 'DiskModule'
                        Version = [version]'2.0.0'
                    }
                }
                return $null
            } -ParameterFilter { $Name -eq 'DiskModule' }

            Mock Import-Module { } -ParameterFilter { $Name -eq 'DiskModule' }
        }

        It 'Imports module from disk when available' {
            { Import-RequiredModule -ModuleName 'DiskModule' } | Should -Not -Throw
            Should -Invoke -CommandName Import-Module -Times 1 -Exactly
        }
    }

    Context 'Module Version Requirements' {
        BeforeAll {
            Mock Get-Module {
                if ($ListAvailable) {
                    return [PSCustomObject]@{
                        Name    = 'VersionModule'
                        Version = [version]'1.0.0'
                    }
                }
                return $null
            } -ParameterFilter { $Name -eq 'VersionModule' }

            Mock Find-Module {
                return [PSCustomObject]@{
                    Name    = 'VersionModule'
                    Version = [version]'2.0.0'
                }
            }

            Mock Install-Module { }
            Mock Import-Module { }
        }

        It 'Attempts install when local version is below minimum' {
            { Import-RequiredModule -ModuleName 'VersionModule' -MinimumVersion '2.0.0' } | Should -Not -Throw
            Should -Invoke -CommandName Find-Module -Times 1
        }
    }

    Context 'Module Not Found' {
        BeforeAll {
            Mock Get-Module { return $null }
            Mock Find-Module { return $null }
        }

        It 'Throws RuntimeException when module not found' {
            # The function wraps ItemNotFoundException in RuntimeException
            { Import-RequiredModule -ModuleName 'NonExistentModule' } | Should -Throw -ExceptionType ([System.Management.Automation.RuntimeException])
        }
    }

    Context 'Error Handling' {
        BeforeAll {
            Mock Get-Module { return $null }
            Mock Find-Module { throw 'Network error' }
        }

        It 'Wraps exceptions in RuntimeException' {
            { Import-RequiredModule -ModuleName 'ErrorModule' } | Should -Throw -ExceptionType ([System.Management.Automation.RuntimeException])
        }
    }
}
