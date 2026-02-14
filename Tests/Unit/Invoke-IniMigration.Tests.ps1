#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Invoke-IniMigration function.
#>

BeforeAll {
    # Dot-source the function directly for testing
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Invoke-IniMigration.ps1'
    . $functionPath

    # Also need Convert-IniToJson for actual conversion
    $convertPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Public\Convert-IniToJson.ps1'
    . $convertPath
}

Describe 'Invoke-IniMigration' {
    Context 'Parameter Validation' {
        It 'Has mandatory IniPath parameter' {
            $command = Get-Command -Name Invoke-IniMigration
            $command.Parameters['IniPath'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has optional SkipPrompt switch parameter' {
            $command = Get-Command -Name Invoke-IniMigration
            $command.Parameters['SkipPrompt'].SwitchParameter | Should -Be $true
        }

        It 'Validates IniPath exists' {
            { Invoke-IniMigration -IniPath 'C:\NonExistent\file.ini' -SkipPrompt } | Should -Throw
        }

        It 'Has OutputType attribute' {
            $command = Get-Command -Name Invoke-IniMigration
            $command.OutputType.Type.Name | Should -Contain 'String'
        }
    }

    Context 'Backup Creation' {
        BeforeAll {
            # Create a valid test INI file
            $script:TestIniContent = @"
[sqlServer]
TEST1=TESTDBSRV01.test.lcl

[database]
TEST1=bplus_test1

[syscat]
TEST1=syscat_test1

[filepathData]
TEST1=D:\MSSQL\Data

[filepathLog]
TEST1=L:\MSSQL\Log

[fileDriveData]
TEST1=bplus:Data:bplus.mdf,bplus_log:Log:bplus.ldf

[fileDriveSyscat]
TEST1=syscat:Data:syscat.mdf,syscat_log:Log:syscat.ldf

[environmentServers]
TEST1=server1.test.lcl,server2.test.lcl

[ipc_daemon]
TEST1=ipc_bplus

[SMTP]
host=smtp.test.lcl
port=25
replyToEmail=noreply@test.lcl
notificationEmail=admin@test.lcl

[NUUPAUSY]
TEST1=TEST1 Environment

[IUSRSource]
TEST1=PROD\IUSR_BPLUS

[IUSRDestination]
TEST1=TEST\IUSR_BPLUS

[AdminSource]
TEST1=PROD\admin

[AdminDestination]
TEST1=TEST\admin

[DummyEmail]
TEST1=noreply@test.lcl

[ManagerCode]
TEST1=DBA,ADMIN
"@
        }

        BeforeEach {
            # Create fresh test INI file for each test
            $script:TestIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'config.ini'
            $script:TestIniContent | Set-Content -Path $script:TestIniPath
        }

        It 'Creates backup file with .ini.bak extension' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $backupPath = "$($script:TestIniPath).bak"
            Test-Path -Path $backupPath | Should -Be $true
        }

        It 'Backup contains original INI content' {
            $originalContent = Get-Content -Path $script:TestIniPath -Raw
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $backupPath = "$($script:TestIniPath).bak"
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Be $originalContent
        }
    }

    Context 'JSON Conversion' {
        BeforeAll {
            $script:TestIniContent = @"
[sqlServer]
TEST1=TESTDBSRV01.test.lcl

[database]
TEST1=bplus_test1

[syscat]
TEST1=syscat_test1

[filepathData]
TEST1=D:\MSSQL\Data

[filepathLog]
TEST1=L:\MSSQL\Log

[fileDriveData]
TEST1=bplus:Data:bplus.mdf,bplus_log:Log:bplus.ldf

[fileDriveSyscat]
TEST1=syscat:Data:syscat.mdf,syscat_log:Log:syscat.ldf

[environmentServers]
TEST1=server1.test.lcl,server2.test.lcl

[ipc_daemon]
TEST1=ipc_bplus

[SMTP]
host=smtp.test.lcl
port=25
replyToEmail=noreply@test.lcl
notificationEmail=admin@test.lcl

[NUUPAUSY]
TEST1=TEST1 Environment

[IUSRSource]
TEST1=PROD\IUSR_BPLUS

[IUSRDestination]
TEST1=TEST\IUSR_BPLUS

[AdminSource]
TEST1=PROD\admin

[AdminDestination]
TEST1=TEST\admin

[DummyEmail]
TEST1=noreply@test.lcl

[ManagerCode]
TEST1=DBA,ADMIN
"@
        }

        BeforeEach {
            $script:TestIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'config.ini'
            $script:TestIniContent | Set-Content -Path $script:TestIniPath
        }

        It 'Creates JSON file with .json extension' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $jsonPath = $script:TestIniPath -replace '\.ini$', '.json'
            Test-Path -Path $jsonPath | Should -Be $true
        }

        It 'Returns path to new JSON file' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $expectedJsonPath = $script:TestIniPath -replace '\.ini$', '.json'
            $result | Should -Be $expectedJsonPath
        }

        It 'Created JSON is valid and parseable' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            { Get-Content -Path $result -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Created JSON contains environment configuration' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $json = Get-Content -Path $result -Raw | ConvertFrom-Json
            $json.environments.TEST1.sqlServer | Should -Be 'TESTDBSRV01.test.lcl'
        }
    }

    Context 'Original File Handling' {
        BeforeAll {
            $script:TestIniContent = @"
[sqlServer]
TEST1=TESTDBSRV01.test.lcl

[database]
TEST1=bplus_test1

[syscat]
TEST1=syscat_test1

[filepathData]
TEST1=D:\MSSQL\Data

[filepathLog]
TEST1=L:\MSSQL\Log

[fileDriveData]
TEST1=bplus:Data:bplus.mdf

[fileDriveSyscat]
TEST1=syscat:Data:syscat.mdf

[environmentServers]
TEST1=server1.test.lcl

[ipc_daemon]
TEST1=ipc_bplus

[SMTP]
host=smtp.test.lcl
replyToEmail=noreply@test.lcl
notificationEmail=admin@test.lcl

[NUUPAUSY]
TEST1=TEST1 Environment

[IUSRSource]
TEST1=PROD\IUSR

[IUSRDestination]
TEST1=TEST\IUSR

[AdminSource]
TEST1=PROD\admin

[AdminDestination]
TEST1=TEST\admin

[DummyEmail]
TEST1=noreply@test.lcl

[ManagerCode]
TEST1=DBA
"@
        }

        BeforeEach {
            $script:TestIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'config.ini'
            $script:TestIniContent | Set-Content -Path $script:TestIniPath
        }

        It 'Original INI file is renamed to .ini.bak' {
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            # Original .ini should not exist
            Test-Path -Path $script:TestIniPath | Should -Be $false

            # .ini.bak should exist
            Test-Path -Path "$($script:TestIniPath).bak" | Should -Be $true
        }
    }

    Context 'SkipPrompt Switch' {
        BeforeAll {
            $script:TestIniContent = @"
[sqlServer]
TEST1=TESTDBSRV01.test.lcl

[database]
TEST1=bplus_test1

[syscat]
TEST1=syscat_test1

[filepathData]
TEST1=D:\MSSQL\Data

[filepathLog]
TEST1=L:\MSSQL\Log

[fileDriveData]
TEST1=bplus:Data:bplus.mdf

[fileDriveSyscat]
TEST1=syscat:Data:syscat.mdf

[environmentServers]
TEST1=server1.test.lcl

[ipc_daemon]
TEST1=ipc_bplus

[SMTP]
host=smtp.test.lcl
replyToEmail=noreply@test.lcl
notificationEmail=admin@test.lcl

[NUUPAUSY]
TEST1=TEST1 Environment

[IUSRSource]
TEST1=PROD\IUSR

[IUSRDestination]
TEST1=TEST\IUSR

[AdminSource]
TEST1=PROD\admin

[AdminDestination]
TEST1=TEST\admin

[DummyEmail]
TEST1=noreply@test.lcl

[ManagerCode]
TEST1=DBA
"@
        }

        BeforeEach {
            $script:TestIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'config.ini'
            $script:TestIniContent | Set-Content -Path $script:TestIniPath
        }

        It 'SkipPrompt bypasses interactive prompt' {
            # This test verifies that with SkipPrompt, no prompt is shown
            # If prompt was required and not mocked, this would hang or fail
            $result = Invoke-IniMigration -IniPath $script:TestIniPath -SkipPrompt

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Throws descriptive error for invalid INI' {
            $invalidIniPath = Join-Path -Path 'TestDrive:' -ChildPath 'invalid.ini'
            'not a valid ini file' | Set-Content -Path $invalidIniPath

            { Invoke-IniMigration -IniPath $invalidIniPath -SkipPrompt } | Should -Throw
        }
    }
}
