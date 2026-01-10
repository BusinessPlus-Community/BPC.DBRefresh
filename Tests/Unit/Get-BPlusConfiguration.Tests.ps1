#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Get-BPlusConfiguration function.
#>

BeforeAll {
    # Dot-source the function directly for testing
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Get-BPlusConfiguration.ps1'
    . $functionPath

    # Path to test fixture
    $script:TestJsonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Fixtures\TestConfig.json'
}

Describe 'Get-BPlusConfiguration' {
    Context 'Parameter Validation' {
        It 'Has mandatory Path parameter' {
            $command = Get-Command -Name Get-BPlusConfiguration
            $command.Parameters['Path'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has mandatory Environment parameter' {
            $command = Get-Command -Name Get-BPlusConfiguration
            $command.Parameters['Environment'].Attributes.Mandatory | Should -Be $true
        }

        It 'Validates Path exists' {
            { Get-BPlusConfiguration -Path 'C:\NonExistent\file.json' -Environment 'TEST1' } | Should -Throw
        }

        It 'Has OutputType attribute' {
            $command = Get-Command -Name Get-BPlusConfiguration
            # PowerShell uses 'PSObject' for PSCustomObject in OutputType
            $command.OutputType.Type.Name | Should -Contain 'PSObject'
        }
    }

    Context 'Configuration Parsing' {
        BeforeAll {
            $script:Config = Get-BPlusConfiguration -Path $script:TestJsonPath -Environment 'TEST1'
        }

        It 'Returns PSCustomObject' {
            $script:Config | Should -BeOfType [PSCustomObject]
        }

        It 'Parses environment name correctly' {
            $script:Config.Environment | Should -Be 'TEST1'
        }

        It 'Parses database server correctly' {
            $script:Config.DatabaseServer | Should -Be 'TESTDBSRV01.test.lcl'
        }

        It 'Parses database names correctly' {
            $script:Config.IfasDatabase | Should -Be 'bplus_test1'
            $script:Config.SyscatDatabase | Should -Be 'syscat_test1'
            $script:Config.AspnetDatabase | Should -Be 'aspnet_test1'
        }

        It 'Parses file paths correctly' {
            $script:Config.FilePaths.Data | Should -Be 'D:\MSSQL\Data'
            $script:Config.FilePaths.Log | Should -Be 'L:\MSSQL\Log'
            $script:Config.FilePaths.Images | Should -Be 'I:\MSSQL\Images'
        }

        It 'Parses server list as array' {
            @($script:Config.Servers).Count | Should -Be 2
            $script:Config.Servers | Should -Contain 'server1.test.lcl'
            $script:Config.Servers | Should -Contain 'server2.test.lcl'
        }

        It 'Parses SMTP settings correctly' {
            $script:Config.SmtpSettings.Host | Should -Be 'smtp.test.lcl'
            $script:Config.SmtpSettings.Port | Should -Be 25
            $script:Config.SmtpSettings.ReplyToEmail | Should -Be 'noreply@test.lcl'
        }

        It 'Parses security account mappings' {
            $script:Config.Security.IusrSource | Should -Be 'PROD\IUSR_BPLUS'
            $script:Config.Security.IusrDestination | Should -Be 'TEST\IUSR_BPLUS'
            $script:Config.Security.AdminSource | Should -Be 'PROD\admin'
            $script:Config.Security.AdminDestination | Should -Be 'TEST\admin'
        }

        It 'Parses manager codes as array' {
            @($script:Config.ManagerCodes).Count | Should -Be 2
            $script:Config.ManagerCodes | Should -Contain 'DBA'
            $script:Config.ManagerCodes | Should -Contain 'ADMIN'
        }

        It 'Builds connection strings' {
            $script:Config.ConnectionStrings.Ifas | Should -Match 'bplus_test1'
            $script:Config.ConnectionStrings.Syscat | Should -Match 'syscat_test1'
        }

        It 'Parses file drive mappings as arrays' {
            @($script:Config.FileDrives.Ifas).Count | Should -Be 2
            @($script:Config.FileDrives.Syscat).Count | Should -Be 2
        }
    }

    Context 'Default Values' {
        BeforeAll {
            # Create a minimal JSON config for testing defaults
            $minimalJson = @{
                environments = @{
                    TEST1 = @{
                        sqlServer = 'server'
                        database = 'db'
                        syscat = 'syscat'
                        filepathData = 'D:\Data'
                        filepathLog = 'L:\Log'
                        fileDriveData = @('db:Data:db.mdf')
                        fileDriveSyscat = @('sc:Data:sc.mdf')
                        environmentServers = @('srv1')
                        ipcDaemon = 'ipc'
                        nuupausy = 'TEXT'
                        iusrSource = 'src\user'
                        iusrDestination = 'dst\user'
                        adminSource = 'src\admin'
                        adminDestination = 'dst\admin'
                        dummyEmail = 'dummy@test'
                        managerCodes = @('MGR')
                    }
                }
                smtp = @{
                    host = 'smtp'
                    replyToEmail = 'reply@test'
                    notificationEmail = 'notify@test'
                }
            } | ConvertTo-Json -Depth 10

            $testFile = New-Item -Path 'TestDrive:\defaults.json' -ItemType File -Force
            $minimalJson | Set-Content -Path $testFile.FullName

            $script:ConfigDefaults = Get-BPlusConfiguration -Path $testFile.FullName -Environment 'TEST1'
        }

        It 'Defaults SMTP port to 25 when not specified' {
            $script:ConfigDefaults.SmtpSettings.Port | Should -Be 25
        }

        It 'Uses AdminSource for DboSource when not specified' {
            $script:ConfigDefaults.Security.DboSource | Should -Be 'src\admin'
        }

        It 'Uses AdminDestination for DboDestination when not specified' {
            $script:ConfigDefaults.Security.DboDestination | Should -Be 'dst\admin'
        }
    }

    Context 'Error Handling' {
        It 'Throws ConfigurationException for missing required values' {
            $invalidJson = @{
                environments = @{
                    TEST1 = @{
                        sqlServer = 'server'
                        # Missing required fields
                    }
                }
                smtp = @{}
            } | ConvertTo-Json -Depth 10

            $testFile = New-Item -Path 'TestDrive:\invalid.json' -ItemType File -Force
            $invalidJson | Set-Content -Path $testFile.FullName

            { Get-BPlusConfiguration -Path $testFile.FullName -Environment 'TEST1' } |
                Should -Throw -ExceptionType ([System.Configuration.ConfigurationException])
        }

        It 'Throws for missing environment' {
            { Get-BPlusConfiguration -Path $script:TestJsonPath -Environment 'NONEXISTENT' } |
                Should -Throw "*not found*"
        }

        It 'Throws for invalid JSON' {
            $invalidFile = New-Item -Path 'TestDrive:\badjson.json' -ItemType File -Force
            'not valid json {{{' | Set-Content -Path $invalidFile.FullName

            { Get-BPlusConfiguration -Path $invalidFile.FullName -Environment 'TEST1' } |
                Should -Throw -ExceptionType ([System.Configuration.ConfigurationException])
        }
    }

    Context 'Cross-Platform Compatibility' {
        It 'Does not require PsIni module' {
            # Verify the function does not call Get-IniContent
            $functionContent = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Get-BPlusConfiguration.ps1') -Raw
            $functionContent | Should -Not -Match 'Get-IniContent'
        }

        It 'Uses native ConvertFrom-Json' {
            $functionContent = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Get-BPlusConfiguration.ps1') -Raw
            $functionContent | Should -Match 'ConvertFrom-Json'
        }
    }

    Context 'INI Migration' {
        BeforeAll {
            # Path to INI test fixture
            $script:TestIniFixturePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Fixtures\TestConfig.ini'

            # Also dot-source required dependencies
            $migrationPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Invoke-IniMigration.ps1'
            . $migrationPath
            $convertPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Convert-IniToJson.ps1'
            . $convertPath
        }

        It 'Has SkipMigrationPrompt switch parameter' {
            $command = Get-Command -Name Get-BPlusConfiguration
            $command.Parameters['SkipMigrationPrompt'].SwitchParameter | Should -Be $true
        }

        It 'Detects INI files by extension' {
            # The function should detect .ini extension and trigger migration
            $functionContent = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Get-BPlusConfiguration.ps1') -Raw
            $functionContent | Should -Match '\.ini\$'
        }

        It 'Migrates INI file and returns valid configuration' {
            # Copy INI fixture to TestDrive for isolation
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'migration_test.ini'
            Copy-Item -Path $script:TestIniFixturePath -Destination $testIniPath

            # Call Get-BPlusConfiguration with INI file (should migrate)
            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify we got a valid configuration
            $config | Should -BeOfType [PSCustomObject]
            $config.Environment | Should -Be 'TEST1'
            $config.DatabaseServer | Should -Be 'TESTDBSRV01.test.lcl'
        }

        It 'Creates JSON file after INI migration' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'creates_json_test.ini'
            Copy-Item -Path $script:TestIniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # JSON file should exist
            $expectedJsonPath = $testIniPath -replace '\.ini$', '.json'
            Test-Path -Path $expectedJsonPath | Should -Be $true
        }

        It 'Creates backup of original INI file' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'backup_test.ini'
            Copy-Item -Path $script:TestIniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Backup should exist
            $backupPath = "$testIniPath.bak"
            Test-Path -Path $backupPath | Should -Be $true
        }

        It 'Renames original INI to .bak after migration' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'rename_test.ini'
            Copy-Item -Path $script:TestIniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Original INI should not exist
            Test-Path -Path $testIniPath | Should -Be $false
        }

        It 'JSON files load directly without migration' {
            # JSON file should not trigger migration logic
            $config = Get-BPlusConfiguration -Path $script:TestJsonPath -Environment 'TEST1'

            # Should work normally
            $config.Environment | Should -Be 'TEST1'

            # No backup should be created for JSON files
            $backupPath = "$($script:TestJsonPath).bak"
            Test-Path -Path $backupPath | Should -Be $false
        }

        It 'Migrated configuration has correct values' {
            $testIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'values_test.ini'
            Copy-Item -Path $script:TestIniFixturePath -Destination $testIniPath

            $config = Get-BPlusConfiguration -Path $testIniPath -Environment 'TEST1' -SkipMigrationPrompt

            # Verify key values match the INI fixture
            $config.IfasDatabase | Should -Be 'bplus_test1'
            $config.SyscatDatabase | Should -Be 'syscat_test1'
            $config.SmtpSettings.Host | Should -Be 'smtp.test.lcl'
            @($config.Servers).Count | Should -Be 2
            @($config.ManagerCodes).Count | Should -Be 2
        }
    }
}
