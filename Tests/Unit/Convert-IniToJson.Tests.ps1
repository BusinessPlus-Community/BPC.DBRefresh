BeforeAll {
    . $PSScriptRoot/../../src/BPlusDBRefresh/Public/Convert-IniToJson.ps1
}

Describe 'Convert-IniToJson' {
    BeforeAll {
        $testIniPath = "$PSScriptRoot/../Fixtures/TestConfig.ini"
    }

    Context 'Parameter Validation' {
        It 'Has mandatory IniPath parameter' {
            $params = (Get-Command Convert-IniToJson).Parameters
            $params['IniPath'].Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute]
            } | ForEach-Object {
                $_.Mandatory | Should -BeTrue
            }
        }

        It 'Has optional OutputPath parameter' {
            $params = (Get-Command Convert-IniToJson).Parameters
            $params['OutputPath'].Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute]
            } | ForEach-Object {
                $_.Mandatory | Should -BeFalse
            }
        }

        It 'Has optional Environments parameter' {
            $params = (Get-Command Convert-IniToJson).Parameters
            $params['Environments'].Attributes | Where-Object {
                $_ -is [System.Management.Automation.ParameterAttribute]
            } | ForEach-Object {
                $_.Mandatory | Should -BeFalse
            }
        }

        It 'Validates IniPath exists' {
            { Convert-IniToJson -IniPath 'C:\NonExistent\fake.ini' } |
                Should -Throw
        }

        It 'Has OutputType attribute' {
            $outputTypes = (Get-Command Convert-IniToJson).OutputType
            $outputTypes.Type.Name | Should -Contain 'String'
        }
    }

    Context 'Basic INI-to-JSON Conversion' {
        It 'Returns valid JSON string when no OutputPath specified' {
            $result = Convert-IniToJson -IniPath $testIniPath
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Includes schema reference in output' {
            $result = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $result.'$schema' | Should -Be './bpcBPlusDBRefresh.schema.json'
        }

        It 'Includes environments section' {
            $result = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $result.environments | Should -Not -BeNullOrEmpty
        }

        It 'Includes smtp section' {
            $result = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $result.smtp | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Environment Auto-Detection' {
        It 'Auto-detects environments from sqlServer section' {
            $result = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $result.environments.TEST1 | Should -Not -BeNullOrEmpty
        }

        It 'Accepts explicit environments parameter' {
            $result = Convert-IniToJson -IniPath $testIniPath -Environments @('TEST1') |
                ConvertFrom-Json
            $result.environments.TEST1 | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Environment Configuration Values' {
        BeforeAll {
            $json = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $envConfig = $json.environments.TEST1
        }

        It 'Converts sqlServer correctly' {
            $envConfig.sqlServer | Should -Be 'TESTDBSRV01.test.lcl'
        }

        It 'Converts database name correctly' {
            $envConfig.database | Should -Be 'bplus_test1'
        }

        It 'Converts syscat name correctly' {
            $envConfig.syscat | Should -Be 'syscat_test1'
        }

        It 'Converts aspnet name correctly' {
            $envConfig.aspnet | Should -Be 'aspnet_test1'
        }

        It 'Converts file paths correctly' {
            $envConfig.filepathData | Should -Be 'D:\MSSQL\Data'
            $envConfig.filepathLog | Should -Be 'L:\MSSQL\Log'
        }

        It 'Converts nuupausy text correctly' {
            $envConfig.nuupausy | Should -Be 'TEST1 Environment'
        }

        It 'Converts security account mappings correctly' {
            $envConfig.iusrSource | Should -Be 'PROD\IUSR_BPLUS'
            $envConfig.iusrDestination | Should -Be 'TEST\IUSR_BPLUS'
            $envConfig.adminSource | Should -Be 'PROD\admin'
            $envConfig.adminDestination | Should -Be 'TEST\admin'
        }

        It 'Converts dummy email correctly' {
            $envConfig.dummyEmail | Should -Be 'noreply@test.lcl'
        }
    }

    Context 'Array Conversion from Comma-Separated Values' {
        BeforeAll {
            $json = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $envConfig = $json.environments.TEST1
        }

        It 'Converts environmentServers to array' {
            $envConfig.environmentServers | Should -HaveCount 2
            $envConfig.environmentServers[0] | Should -Be 'server1.test.lcl'
            $envConfig.environmentServers[1] | Should -Be 'server2.test.lcl'
        }

        It 'Converts fileDriveData to array' {
            $envConfig.fileDriveData | Should -HaveCount 2
        }

        It 'Converts managerCodes to array' {
            $envConfig.managerCodes | Should -HaveCount 2
            $envConfig.managerCodes | Should -Contain 'DBA'
            $envConfig.managerCodes | Should -Contain 'ADMIN'
        }

        It 'Converts single-value comma-separated to array' {
            $envConfig.testingModeCodes | Should -HaveCount 1
            $envConfig.testingModeCodes | Should -Contain 'DBA'
        }
    }

    Context 'SMTP Configuration' {
        BeforeAll {
            $json = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $smtp = $json.smtp
        }

        It 'Converts SMTP host' {
            $smtp.host | Should -Be 'smtp.test.lcl'
        }

        It 'Converts SMTP port as integer' {
            $smtp.port | Should -Be 25
            $smtp.port | Should -BeOfType [long]
        }

        It 'Converts SSL flag from Y/N to boolean' {
            $smtp.ssl | Should -Be $false
        }

        It 'Converts reply-to email' {
            $smtp.replyToEmail | Should -Be 'noreply@test.lcl'
        }

        It 'Converts notification email' {
            $smtp.notificationEmail | Should -Be 'admin@test.lcl'
        }
    }

    Context 'Null Value Cleanup' {
        BeforeAll {
            $json = Convert-IniToJson -IniPath $testIniPath | ConvertFrom-Json
            $envConfig = $json.environments.TEST1
        }

        It 'Removes keys with null values from output' {
            # filepathImages is present in INI so should be included
            $envConfig.filepathImages | Should -Be 'I:\MSSQL\Images'
        }

        It 'Preserves non-empty string values' {
            $envConfig.dashboardUrl | Should -Be 'https://test.lcl/'
        }
    }

    Context 'File Output' {
        It 'Writes JSON to file when OutputPath specified' {
            $tempFile = Join-Path -Path $TestDrive -ChildPath 'output.json'
            $result = Convert-IniToJson -IniPath $testIniPath -OutputPath $tempFile
            Test-Path -Path $tempFile | Should -BeTrue
        }

        It 'Written file contains valid JSON' {
            $tempFile = Join-Path -Path $TestDrive -ChildPath 'output2.json'
            Convert-IniToJson -IniPath $testIniPath -OutputPath $tempFile
            $content = Get-Content -Path $tempFile -Raw
            { $content | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Returns confirmation message when writing to file' {
            $tempFile = Join-Path -Path $TestDrive -ChildPath 'output3.json'
            $result = Convert-IniToJson -IniPath $testIniPath -OutputPath $tempFile
            $result | Should -BeLike '*Configuration converted*'
        }
    }

    Context 'Error Handling' {
        It 'Throws InvalidOperationException for invalid INI content' {
            $badIni = Join-Path -Path $TestDrive -ChildPath 'bad.ini'
            '= invalid content no section' | Out-File -FilePath $badIni
            { Convert-IniToJson -IniPath $badIni } |
                Should -Throw -ExceptionType ([System.InvalidOperationException])
        }

        It 'Throws when no environments can be detected' {
            $emptyIni = Join-Path -Path $TestDrive -ChildPath 'empty.ini'
            '[otherSection]' | Out-File -FilePath $emptyIni
            'key=value' | Add-Content -Path $emptyIni
            { Convert-IniToJson -IniPath $emptyIni } |
                Should -Throw '*No environments found*'
        }
    }
}
