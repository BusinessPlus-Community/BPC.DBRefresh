#Requires -Modules Pester
<#
.SYNOPSIS
    Unit tests for Build-FileMapping function.
#>

BeforeAll {
    # Dot-source the function directly for testing
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\BPlusDBRefresh\Private\Restore-BPlusDatabase.ps1'
    . $functionPath
}

Describe 'Build-FileMapping' {
    Context 'Parameter Validation' {
        It 'Has mandatory FileDrives parameter' {
            $command = Get-Command -Name Build-FileMapping
            $command.Parameters['FileDrives'].Attributes.Mandatory | Should -Be $true
        }

        It 'Has mandatory FilePaths parameter' {
            $command = Get-Command -Name Build-FileMapping
            $command.Parameters['FilePaths'].Attributes.Mandatory | Should -Be $true
        }

        It 'Returns hashtable type' {
            $command = Get-Command -Name Build-FileMapping
            $command.OutputType.Type.Name | Should -Contain 'hashtable'
        }
    }

    Context 'File Mapping Construction' {
        BeforeAll {
            $script:FilePaths = [PSCustomObject]@{
                Data   = 'D:\MSSQL\Data'
                Log    = 'L:\MSSQL\Log'
                Images = 'I:\MSSQL\Images'
            }
        }

        It 'Maps data files to Data path' {
            $fileDrives = @('bplus:Data:bplus.mdf')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result | Should -BeOfType [hashtable]
            $result['bplus'] | Should -Be 'D:\MSSQL\Data\bplus.mdf'
        }

        It 'Maps log files to Log path' {
            $fileDrives = @('bplus_log:Log:bplus.ldf')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['bplus_log'] | Should -Be 'L:\MSSQL\Log\bplus.ldf'
        }

        It 'Maps image files to Images path' {
            $fileDrives = @('bplus_images:Images:bplus_img.ndf')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['bplus_images'] | Should -Be 'I:\MSSQL\Images\bplus_img.ndf'
        }

        It 'Handles multiple file mappings' {
            $fileDrives = @(
                'bplus:Data:bplus.mdf',
                'bplus_log:Log:bplus.ldf',
                'bplus_img:Images:bplus_img.ndf'
            )
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result.Count | Should -Be 3
            $result['bplus'] | Should -Be 'D:\MSSQL\Data\bplus.mdf'
            $result['bplus_log'] | Should -Be 'L:\MSSQL\Log\bplus.ldf'
            $result['bplus_img'] | Should -Be 'I:\MSSQL\Images\bplus_img.ndf'
        }

        It 'Defaults unknown drive types to Data path' {
            $fileDrives = @('unknown:UnknownType:file.mdf')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['unknown'] | Should -Be 'D:\MSSQL\Data\file.mdf'
        }

        It 'Trims whitespace from parts' {
            $fileDrives = @(' bplus : Data : bplus.mdf ')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['bplus'] | Should -Be 'D:\MSSQL\Data\bplus.mdf'
        }

        It 'Ignores malformed entries with fewer than 3 parts' {
            $fileDrives = @('bplus:Data', 'valid:Data:file.mdf')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result.Count | Should -Be 1
            $result.ContainsKey('bplus') | Should -Be $false
            $result['valid'] | Should -Be 'D:\MSSQL\Data\file.mdf'
        }

        It 'Returns empty hashtable for unparseable input' {
            # Input with only 2 parts (missing filename) should be skipped
            $fileDrives = @('incomplete:Data')
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result | Should -BeOfType [hashtable]
            $result.Count | Should -Be 0
        }
    }

    Context 'Real-world Scenarios' {
        BeforeAll {
            $script:FilePaths = [PSCustomObject]@{
                Data   = 'D:\MSSQL14.MSSQLSERVER\MSSQL\Data'
                Log    = 'L:\MSSQL14.MSSQLSERVER\MSSQL\Log'
                Images = 'I:\MSSQL14.MSSQLSERVER\MSSQL\Images'
            }
        }

        It 'Handles typical IFAS database file mapping' {
            $fileDrives = @(
                'ifas:Data:ifastest1.MDF',
                'ifas_2:Images:ifastest1_2.NDF',
                'ifas_log:Log:ifastest1_log.LDF'
            )
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['ifas'] | Should -Be 'D:\MSSQL14.MSSQLSERVER\MSSQL\Data\ifastest1.MDF'
            $result['ifas_2'] | Should -Be 'I:\MSSQL14.MSSQLSERVER\MSSQL\Images\ifastest1_2.NDF'
            $result['ifas_log'] | Should -Be 'L:\MSSQL14.MSSQLSERVER\MSSQL\Log\ifastest1_log.LDF'
        }

        It 'Handles typical syscat database file mapping' {
            $fileDrives = @(
                'syscat:Data:syscat_test.MDF',
                'syscat_log:Log:syscat_test_log.LDF'
            )
            $result = Build-FileMapping -FileDrives $fileDrives -FilePaths $script:FilePaths

            $result['syscat'] | Should -Be 'D:\MSSQL14.MSSQLSERVER\MSSQL\Data\syscat_test.MDF'
            $result['syscat_log'] | Should -Be 'L:\MSSQL14.MSSQLSERVER\MSSQL\Log\syscat_test_log.LDF'
        }
    }
}
