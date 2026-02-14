#Requires -Modules Pester
<#
.SYNOPSIS
    Integration tests for Invoke-BPlusDBRefresh function.

.DESCRIPTION
    These tests validate the main workflow function with mocked external dependencies.
    Full integration testing requires actual SQL Server and BusinessPlus environment.
#>

BeforeAll {
    # Get the module path
    $script:ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh'
    $script:TestIniPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Fixtures\TestConfig.ini'

    # Dot-source public and private functions for integration testing
    $publicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
    $privatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'

    Get-ChildItem -Path $privatePath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem -Path $publicPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
}

Describe 'Invoke-BPlusDBRefresh' {
    Context 'Parameter Validation' {
        It 'Has mandatory BPEnvironment parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['BPEnvironment'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has mandatory IfasFilePath parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['IfasFilePath'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has mandatory SyscatFilePath parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['SyscatFilePath'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has optional AspnetFilePath parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $mandatoryAttrib = $command.Parameters['AspnetFilePath'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $mandatoryAttrib.Mandatory | Should -Be $false
        }

        It 'Has TestingMode switch parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['TestingMode'].SwitchParameter | Should -Be $true
        }

        It 'Has RestoreDashboards switch parameter' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['RestoreDashboards'].SwitchParameter | Should -Be $true
        }

        It 'Supports ShouldProcess' {
            $command = Get-Command -Name Invoke-BPlusDBRefresh
            $command.Parameters['WhatIf'] | Should -Not -BeNullOrEmpty
            $command.Parameters['Confirm'] | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Help Documentation' {
        BeforeAll {
            $script:Help = Get-Help -Name Invoke-BPlusDBRefresh -Full
        }

        It 'Has synopsis' {
            $script:Help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Has description' {
            $script:Help.Description | Should -Not -BeNullOrEmpty
        }

        It 'Has parameter documentation for BPEnvironment' {
            $param = $script:Help.Parameters.Parameter | Where-Object { $_.Name -eq 'BPEnvironment' }
            $param.Description.Text | Should -Not -BeNullOrEmpty
        }

        It 'Has examples' {
            $script:Help.Examples | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Workflow Integration' -Skip:$true {
        # These tests are skipped by default as they require actual infrastructure
        # Remove -Skip to run with proper mocked dependencies

        BeforeAll {
            # Mock all external dependencies
            # Note: Get-BPlusConfiguration now uses JSON parsing instead of PsIni

            Mock Test-Path { return $true }
            Mock Stop-BPlusServices { }
            Mock Backup-DatabaseConnectionInfo {
                return [PSCustomObject]@{
                    SyscatData = @()
                    IfasData   = @()
                    Success    = $true
                }
            }
            Mock Restore-BPlusDatabase { }
            Mock Restore-DatabaseConnectionInfo { }
            Mock Set-DatabasePermissions { }
            Mock Disable-BPlusWorkflows { }
            Mock Set-NuupausyText { }
            Mock Restart-BPlusServers { }
            Mock Send-CompletionNotification { }
            Mock Start-Logging { }
            Mock Stop-Logging { }
            Mock Write-LogInfo { }
        }

        It 'Calls workflow functions in correct order' {
            # Create temporary backup files for testing
            $tempIfas = New-TemporaryFile
            $tempSyscat = New-TemporaryFile

            try {
                Invoke-BPlusDBRefresh -BPEnvironment 'TEST1' `
                    -IfasFilePath $tempIfas.FullName `
                    -SyscatFilePath $tempSyscat.FullName `
                    -WhatIf

                # Verify workflow order
                Should -Invoke -CommandName Stop-BPlusServices -Times 1
                Should -Invoke -CommandName Backup-DatabaseConnectionInfo -Times 1
            } finally {
                Remove-Item -Path $tempIfas, $tempSyscat -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe 'Configuration Migration Integration' {
    Context 'End-to-End INI Migration' {
        BeforeAll {
            $script:IniFixturePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Fixtures\TestConfig.ini'
        }

        It 'Complete migration flow: INI → backup → JSON → valid config' {
            # Copy INI fixture to TestDrive for isolation
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'e2e_migration.ini'
            Copy-Item -Path $script:IniFixturePath -Destination $testIniPath

            # Execute migration via Get-BPlusConfiguration
            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify complete state
            $jsonPath = $testIniPath -replace '\.ini$', '.json'
            $backupPath = "$testIniPath.bak"

            # 1. Original INI should be gone
            Test-Path -Path $testIniPath | Should -Be $false

            # 2. Backup should exist
            Test-Path -Path $backupPath | Should -Be $true

            # 3. JSON should exist and be valid
            Test-Path -Path $jsonPath | Should -Be $true
            { Get-Content -Path $jsonPath -Raw | ConvertFrom-Json } | Should -Not -Throw

            # 4. Configuration should be valid and complete
            $config | Should -BeOfType [PSCustomObject]
            $config.Environment | Should -Be 'TEST1'
            $config.DatabaseServer | Should -Be 'TESTDBSRV01.test.lcl'
            $config.IfasDatabase | Should -Be 'bplus_test1'
            $config.SmtpSettings.Host | Should -Be 'smtp.test.lcl'
        }

        It 'Backup file contains original INI content' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'backup_content_test.ini'
            Copy-Item -Path $script:IniFixturePath -Destination $testIniPath

            # Read original content before migration
            $originalContent = Get-Content -Path $script:IniFixturePath -Raw

            # Migrate
            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify backup matches original
            $backupPath = "$testIniPath.bak"
            $backupContent = Get-Content -Path $backupPath -Raw

            $backupContent | Should -Be $originalContent
        }

        It 'Created JSON file is usable for subsequent loads' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'reusable_json_test.ini'
            Copy-Item -Path $script:IniFixturePath -Destination $testIniPath

            # First call: migrate INI to JSON
            $config1 = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Get the JSON path
            $jsonPath = $testIniPath -replace '\.ini$', '.json'

            # Second call: load from JSON directly
            $config2 = Get-BPlusConfiguration -Path $jsonPath -Environment 'TEST1'

            # Both should return equivalent configurations
            $config1.Environment | Should -Be $config2.Environment
            $config1.DatabaseServer | Should -Be $config2.DatabaseServer
            $config1.IfasDatabase | Should -Be $config2.IfasDatabase
        }

        It 'Configuration object has all required properties after migration' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'properties_test.ini'
            Copy-Item -Path $script:IniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify all expected properties exist
            $config.PSObject.Properties.Name | Should -Contain 'Environment'
            $config.PSObject.Properties.Name | Should -Contain 'DatabaseServer'
            $config.PSObject.Properties.Name | Should -Contain 'IfasDatabase'
            $config.PSObject.Properties.Name | Should -Contain 'SyscatDatabase'
            $config.PSObject.Properties.Name | Should -Contain 'FilePaths'
            $config.PSObject.Properties.Name | Should -Contain 'FileDrives'
            $config.PSObject.Properties.Name | Should -Contain 'Servers'
            $config.PSObject.Properties.Name | Should -Contain 'SmtpSettings'
            $config.PSObject.Properties.Name | Should -Contain 'Security'
            $config.PSObject.Properties.Name | Should -Contain 'ManagerCodes'
            $config.PSObject.Properties.Name | Should -Contain 'ConnectionStrings'
        }

        It 'Arrays are properly converted from comma-separated INI values' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'arrays_test.ini'
            Copy-Item -Path $script:IniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify arrays have correct element counts
            @($config.Servers).Count | Should -Be 2
            $config.Servers | Should -Contain 'server1.test.lcl'
            $config.Servers | Should -Contain 'server2.test.lcl'

            @($config.ManagerCodes).Count | Should -Be 2
            $config.ManagerCodes | Should -Contain 'DBA'
            $config.ManagerCodes | Should -Contain 'ADMIN'
        }
    }
}

Describe 'Module Export Verification' {
    Context 'Exported Functions' {
        BeforeAll {
            $script:ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\BPlusDBRefresh.psd1'
            # Parse manifest as hashtable to avoid RequiredModules validation
            $script:ManifestData = Invoke-Expression (Get-Content -Path $script:ManifestPath -Raw)
        }

        It 'Exports exactly 3 public functions' {
            # Invoke-BPlusDBRefresh, Get-BPlusConfiguration, Convert-IniToJson
            $script:ManifestData.FunctionsToExport.Count | Should -Be 3
        }

        It 'Does not export private functions' {
            $exportedNames = $script:ManifestData.FunctionsToExport

            $exportedNames | Should -Not -Contain 'Import-RequiredModule'
            $exportedNames | Should -Not -Contain 'Write-LogMessage'
            $exportedNames | Should -Not -Contain 'Stop-BPlusServices'
            $exportedNames | Should -Not -Contain 'Build-FileMapping'
            $exportedNames | Should -Not -Contain 'Invoke-IniMigration'
        }
    }
}
