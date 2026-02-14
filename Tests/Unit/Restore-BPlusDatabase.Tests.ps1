#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Restore-BPlusDatabase function.
#>

BeforeAll {
    # Mock external dependencies BEFORE dot-sourcing
    function Write-LogInfo { param($LogPath, $Message) }
    function Write-LogError { param($LogPath, $Message) }

    # Dot-source the function for testing
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Restore-BPlusDatabase.ps1'
    . $functionPath
}

Describe 'Restore-BPlusDatabase' {
    Context 'Parameter Validation' {
        It 'Has mandatory Configuration parameter' {
            $command = Get-Command -Name Restore-BPlusDatabase
            $param = $command.Parameters['Configuration']
            $param.Attributes.Mandatory | Should -Contain $true
        }

        It 'Has mandatory DatabaseType parameter' {
            $command = Get-Command -Name Restore-BPlusDatabase
            $param = $command.Parameters['DatabaseType']
            $param.Attributes.Mandatory | Should -Contain $true
        }

        It 'Has mandatory BackupPath parameter' {
            $command = Get-Command -Name Restore-BPlusDatabase
            $param = $command.Parameters['BackupPath']
            $param.Attributes.Mandatory | Should -Contain $true
        }

        It 'Has optional LogFile parameter' {
            $command = Get-Command -Name Restore-BPlusDatabase
            $param = $command.Parameters['LogFile']
            $mandatoryAttrib = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $mandatoryAttrib.Mandatory | Should -Be $false
        }

        It 'Has optional SqlCredential parameter of type PSCredential' {
            $command = Get-Command -Name Restore-BPlusDatabase
            $param = $command.Parameters['SqlCredential']

            # Parameter should exist
            $param | Should -Not -BeNullOrEmpty

            # Parameter should not be mandatory
            $mandatoryAttrib = $param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $mandatoryAttrib.Mandatory | Should -Be $false

            # Parameter type should be PSCredential
            $param.ParameterType.Name | Should -Be 'PSCredential'
        }
    }

    Context 'SqlCredential Pass-Through Behavior' {
        BeforeAll {
            # Setup test configuration
            $script:TestConfig = [PSCustomObject]@{
                DatabaseServer = 'localhost'
                IfasDatabase   = 'bplustest'
                FilePaths      = [PSCustomObject]@{
                    Data   = '/var/opt/mssql/data'
                    Log    = '/var/opt/mssql/data'
                    Images = $null
                }
                FileDrives     = [PSCustomObject]@{
                    Ifas = @('bplus:Data:bplus.mdf', 'bplus_log:Log:bplus_log.ldf')
                }
            }

            # Create a temporary backup file for ValidateScript
            $script:TempBackupFile = New-TemporaryFile
        }

        AfterAll {
            if ($script:TempBackupFile -and (Test-Path $script:TempBackupFile)) {
                Remove-Item -Path $script:TempBackupFile -Force
            }
        }

        It 'Passes SqlCredential to Restore-DbaDatabase when provided' {
            # Arrange
            $testCred = New-Object System.Management.Automation.PSCredential('sa', (ConvertTo-SecureString 'TestPassword123!' -AsPlainText -Force))
            Mock Restore-DbaDatabase { [PSCustomObject]@{ Success = $true } } -ParameterFilter {
                $SqlCredential -and $SqlCredential.UserName -eq 'sa'
            }

            # Act
            Restore-BPlusDatabase -Configuration $script:TestConfig `
                -DatabaseType 'Ifas' `
                -BackupPath $script:TempBackupFile `
                -SqlCredential $testCred `
                -Confirm:$false

            # Assert
            Should -Invoke Restore-DbaDatabase -Times 1 -ParameterFilter {
                $SqlCredential -and $SqlCredential.UserName -eq 'sa'
            }
        }

        It 'Does not pass SqlCredential to Restore-DbaDatabase when omitted' {
            # Arrange
            Mock Restore-DbaDatabase { [PSCustomObject]@{ Success = $true } } -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('SqlCredential')
            }

            # Act
            Restore-BPlusDatabase -Configuration $script:TestConfig `
                -DatabaseType 'Ifas' `
                -BackupPath $script:TempBackupFile `
                -Confirm:$false

            # Assert
            Should -Invoke Restore-DbaDatabase -Times 1 -ParameterFilter {
                -not $PSBoundParameters.ContainsKey('SqlCredential')
            }
        }

        It 'Does not pass null SqlCredential when parameter is omitted' {
            # Arrange
            Mock Restore-DbaDatabase { [PSCustomObject]@{ Success = $true } } -ParameterFilter {
                # Verify SqlCredential is not in bound parameters at all
                # (not just null, but truly absent)
                $PSBoundParameters.Keys -notcontains 'SqlCredential'
            }

            # Act
            Restore-BPlusDatabase -Configuration $script:TestConfig `
                -DatabaseType 'Ifas' `
                -BackupPath $script:TempBackupFile `
                -Confirm:$false

            # Assert
            Should -Invoke Restore-DbaDatabase -Times 1 -ParameterFilter {
                $PSBoundParameters.Keys -notcontains 'SqlCredential'
            }
        }
    }

    Context 'Backwards Compatibility' {
        BeforeAll {
            $script:TestConfig = [PSCustomObject]@{
                DatabaseServer = 'localhost'
                IfasDatabase   = 'bplustest'
                FilePaths      = [PSCustomObject]@{
                    Data   = '/var/opt/mssql/data'
                    Log    = '/var/opt/mssql/data'
                    Images = $null
                }
                FileDrives     = [PSCustomObject]@{
                    Ifas = @('bplus:Data:bplus.mdf', 'bplus_log:Log:bplus_log.ldf')
                }
            }
            $script:TempBackupFile = New-TemporaryFile
        }

        AfterAll {
            if ($script:TempBackupFile -and (Test-Path $script:TempBackupFile)) {
                Remove-Item -Path $script:TempBackupFile -Force
            }
        }

        It 'Works without SqlCredential parameter (Windows auth)' {
            # Arrange
            Mock Restore-DbaDatabase { [PSCustomObject]@{ Success = $true } }

            # Act
            $result = Restore-BPlusDatabase -Configuration $script:TestConfig `
                -DatabaseType 'Ifas' `
                -BackupPath $script:TempBackupFile `
                -Confirm:$false

            # Assert
            Should -Invoke Restore-DbaDatabase -Times 1
        }
    }
}
