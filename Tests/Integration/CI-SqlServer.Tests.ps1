#Requires -Modules Pester
<#
.SYNOPSIS
    CI/CD integration tests for SQL Server backup/restore workflow.

.DESCRIPTION
    These tests validate the module's core backup/restore functionality against
    a live SQL Server 2022 Linux instance. Designed to run in GitHub Actions CI.

    Prerequisites:
    - SQL Server accessible at localhost
    - SA credentials in $env:SA_PASSWORD
    - dbatools module installed

.NOTES
    Tagged with 'CI' for selective execution in CI pipelines.
#>

BeforeAll {
    # Module paths
    $script:ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh'
    $script:CIConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\bpcBPlusDBRefresh-ci.json'
    $script:CISqlScriptPath = Join-Path -Path $script:ModulePath -ChildPath 'Resources\SQL\CI-CreateTables.sql'

    # Dot-source all module functions for integration testing
    $publicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
    $privatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'

    Get-ChildItem -Path $privatePath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
    Get-ChildItem -Path $publicPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }

    # SQL Server connection details
    $script:SqlInstance = 'localhost'
    $script:SourceDbName = 'bplus'
    $script:TargetDbName = 'bplustest1'
    $script:BackupPath = '/tmp/bplus.bak'

    # Build SQL credential from environment variable
    if (-not $env:SA_PASSWORD) {
        throw 'SA_PASSWORD environment variable not set. Required for CI SQL Server authentication.'
    }

    # PSScriptAnalyzer: ConvertTo-SecureString with -AsPlainText is required in CI/CD contexts
    # where credentials come from environment variables. No encrypted alternative exists for
    # automated pipeline credential creation. This is standard practice in GitHub Actions.
    $securePassword = ConvertTo-SecureString -String $env:SA_PASSWORD -AsPlainText -Force # PSScriptAnalyzer suppress
    $script:SqlCredential = New-Object System.Management.Automation.PSCredential ('sa', $securePassword)
}

Describe 'CI SQL Server Integration Tests' -Tag 'CI' {

    Context 'Setup: Create source database and tables' {
        It 'Creates the source database "bplus"' {
            # Remove if exists
            $existingDb = Get-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -ErrorAction SilentlyContinue
            if ($existingDb) {
                Remove-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Confirm:$false
            }

            # Create new database
            $newDb = New-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Name $script:SourceDbName -ErrorAction Stop
            $newDb.Name | Should -Be $script:SourceDbName
        }

        It 'Executes CI-CreateTables.sql to create stub tables' {
            $sqlScript = Get-Content -Path $script:CISqlScriptPath -Raw
            Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Query $sqlScript -ErrorAction Stop

            # Verify tables exist
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName
            $tables.Name | Should -Contain 'wf_model'
            $tables.Name | Should -Contain 'wf_schedule'
            $tables.Name | Should -Contain 'wf_instance'
            $tables.Name | Should -Contain 'us_usno_mstr'
            $tables.Name | Should -Contain 'hr_empmstr'
        }

        It 'Verifies seed data was inserted' {
            $wfModelCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Query 'SELECT COUNT(*) as RowCount FROM wf_model' -As SingleValue
            $wfModelCount | Should -BeGreaterThan 0
        }
    }

    Context 'Backup: Create backup file' {
        It 'Backs up the source database to /tmp/bplus.bak' {
            # Remove old backup if exists
            if (Test-Path -Path $script:BackupPath) {
                Remove-Item -Path $script:BackupPath -Force
            }

            # Perform backup
            $backup = Backup-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Path $script:BackupPath -ErrorAction Stop
            $backup.Database | Should -Be $script:SourceDbName
        }

        It 'Verifies backup file exists' {
            Test-Path -Path $script:BackupPath | Should -Be $true
        }

        It 'Verifies backup file is not empty' {
            $fileInfo = Get-Item -Path $script:BackupPath
            $fileInfo.Length | Should -BeGreaterThan 0
        }
    }

    Context 'Configuration: Load CI config' {
        BeforeAll {
            $script:Config = Get-BPlusConfiguration -Path $script:CIConfigPath -Environment 'CI'
        }

        It 'Loads CI configuration successfully' {
            $script:Config | Should -Not -BeNullOrEmpty
        }

        It 'Returns correct DatabaseServer (localhost)' {
            $script:Config.DatabaseServer | Should -Be 'localhost'
        }

        It 'Returns correct IfasDatabase (bplustest1)' {
            $script:Config.IfasDatabase | Should -Be 'bplustest1'
        }

        It 'Returns Linux file paths' {
            $script:Config.FilePaths.Data | Should -Match '^/'
            $script:Config.FilePaths.Log | Should -Match '^/'
        }

        It 'Returns file drive mappings for restore' {
            $script:Config.FileDrives.Ifas | Should -HaveCount 2
            $script:Config.FileDrives.Ifas[0] | Should -Match 'bplus:Data:bplustest1.mdf'
        }
    }

    Context 'Restore: Restore database using module function' {
        It 'Removes target database if it exists' {
            $existingDb = Get-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -ErrorAction SilentlyContinue
            if ($existingDb) {
                Remove-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Confirm:$false
            }
            $existingDb = Get-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -ErrorAction SilentlyContinue
            $existingDb | Should -BeNullOrEmpty
        }

        It 'Calls Restore-BPlusDatabase with SqlCredential parameter' {
            {
                Restore-BPlusDatabase `
                    -Configuration $script:Config `
                    -DatabaseType 'Ifas' `
                    -BackupPath $script:BackupPath `
                    -SqlCredential $script:SqlCredential `
                    -Confirm:$false `
                    -ErrorAction Stop
            } | Should -Not -Throw
        }

        It 'Verifies target database exists after restore' {
            $restoredDb = Get-DbaDatabase -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -ErrorAction Stop
            $restoredDb.Name | Should -Be $script:TargetDbName
        }
    }

    Context 'Verification: Verify restored data integrity' {
        It 'Restored database contains wf_model table' {
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName
            $tables.Name | Should -Contain 'wf_model'
        }

        It 'Restored database contains wf_schedule table' {
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName
            $tables.Name | Should -Contain 'wf_schedule'
        }

        It 'Restored database contains wf_instance table' {
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName
            $tables.Name | Should -Contain 'wf_instance'
        }

        It 'Restored database contains us_usno_mstr table' {
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName
            $tables.Name | Should -Contain 'us_usno_mstr'
        }

        It 'Restored database contains hr_empmstr table' {
            $tables = Get-DbaDbTable -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName
            $tables.Name | Should -Contain 'hr_empmstr'
        }

        It 'Restored wf_model table has correct row count' {
            $sourceCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Query 'SELECT COUNT(*) as RowCount FROM wf_model' -As SingleValue
            $targetCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Query 'SELECT COUNT(*) as RowCount FROM wf_model' -As SingleValue
            $targetCount | Should -Be $sourceCount
        }

        It 'Restored us_usno_mstr table has correct row count' {
            $sourceCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Query 'SELECT COUNT(*) as RowCount FROM us_usno_mstr' -As SingleValue
            $targetCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Query 'SELECT COUNT(*) as RowCount FROM us_usno_mstr' -As SingleValue
            $targetCount | Should -Be $sourceCount
        }

        It 'Restored hr_empmstr table has correct row count' {
            $sourceCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:SourceDbName -Query 'SELECT COUNT(*) as RowCount FROM hr_empmstr' -As SingleValue
            $targetCount = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Query 'SELECT COUNT(*) as RowCount FROM hr_empmstr' -As SingleValue
            $targetCount | Should -Be $sourceCount
        }

        It 'Restored data contains expected workflow model IDs' {
            $modelIds = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Query 'SELECT wf_model_id FROM wf_model' -As PSObject
            $modelIds.wf_model_id | Should -Contain 'JOB'
            $modelIds.wf_model_id | Should -Contain 'DO_ARCHIVE'
        }

        It 'Restored data contains expected user email addresses' {
            $emails = Invoke-DbaQuery -SqlInstance $script:SqlInstance -SqlCredential $script:SqlCredential -Database $script:TargetDbName -Query 'SELECT us_email FROM us_usno_mstr' -As PSObject
            $emails.us_email | Should -Contain 'user1@example.com'
        }
    }
}
