BeforeAll {
  $moduleRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
  $modulePath = Join-Path -Path $moduleRoot -ChildPath 'BPC.DBRefresh'

  # Remove any existing module instances first
  Get-Module -Name BPC.DBRefresh | Remove-Module -Force

  # Import the module
  Import-Module $modulePath -Force
}

Describe 'Invoke-BPERPDatabaseRestore' {
  Context 'Function exists' {
    It 'Should have the Invoke-BPERPDatabaseRestore function' {
      Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh | Should -Not -BeNullOrEmpty
    }

    It 'Should have the correct parameters' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters.Keys | Should -Contain 'BPEnvironment'
      $command.Parameters.Keys | Should -Contain 'IfasFilePath'
      $command.Parameters.Keys | Should -Contain 'SyscatFilePath'
      $command.Parameters.Keys | Should -Contain 'AspnetFilePath'
      $command.Parameters.Keys | Should -Contain 'TestingMode'
      $command.Parameters.Keys | Should -Contain 'RestoreDashboards'
      $command.Parameters.Keys | Should -Contain 'ConfigPath'
      $command.Parameters.Keys | Should -Contain 'SkipConfirmation'
    }

    It 'Should have mandatory parameters marked correctly' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['BPEnvironment'].Attributes.Mandatory | Should -Contain $true
      $command.Parameters['IfasFilePath'].Attributes.Mandatory | Should -Contain $true
      $command.Parameters['SyscatFilePath'].Attributes.Mandatory | Should -Contain $true
      $command.Parameters['AspnetFilePath'].Attributes.Mandatory | Should -Contain $false
      $command.Parameters['TestingMode'].Attributes.Mandatory | Should -Contain $false
      $command.Parameters['RestoreDashboards'].Attributes.Mandatory | Should -Contain $false
    }
  }

  Context 'Parameter validation' {
    It 'Should accept String type for BPEnvironment parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['BPEnvironment'].ParameterType.Name | Should -Be 'String'
    }

    It 'Should accept String type for IfasFilePath parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['IfasFilePath'].ParameterType.Name | Should -Be 'String'
    }

    It 'Should accept String type for SyscatFilePath parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['SyscatFilePath'].ParameterType.Name | Should -Be 'String'
    }

    It 'Should accept String type for AspnetFilePath parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['AspnetFilePath'].ParameterType.Name | Should -Be 'String'
    }

    It 'Should accept SwitchParameter type for TestingMode parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['TestingMode'].ParameterType.Name | Should -Be 'SwitchParameter'
    }

    It 'Should accept SwitchParameter type for RestoreDashboards parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['RestoreDashboards'].ParameterType.Name | Should -Be 'SwitchParameter'
    }

    It 'Should accept String type for ConfigPath parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['ConfigPath'].ParameterType.Name | Should -Be 'String'
    }

    It 'Should accept SwitchParameter type for SkipConfirmation parameter' {
      $command = Get-Command -Name Invoke-BPERPDatabaseRestore -Module BPC.DBRefresh
      $command.Parameters['SkipConfirmation'].ParameterType.Name | Should -Be 'SwitchParameter'
    }
  }

  Context 'Function behavior' -Tag 'Integration' {
    It 'Should throw when mandatory parameters are missing' -Skip {
      # This test is skipped because it causes interactive prompts during build
      { Invoke-BPERPDatabaseRestore } | Should -Throw
    }

    It 'Should validate backup path exists' {
      $nonExistentPath = 'C:\NonExistent\backup.bak'
      { Invoke-BPERPDatabaseRestore -BPEnvironment 'TEST' -IfasFilePath $nonExistentPath -SyscatFilePath $nonExistentPath } | Should -Throw
    }

    It 'Should validate configuration file path' {
      # Create temporary backup files
      $tempIfas = New-TemporaryFile
      $tempSyscat = New-TemporaryFile

      Mock -CommandName Get-BPERPEnvironmentConfig -ModuleName BPC.DBRefresh -MockWith { throw 'Config not found' }

      { Invoke-BPERPDatabaseRestore -BPEnvironment 'TEST' -IfasFilePath $tempIfas.FullName -SyscatFilePath $tempSyscat.FullName -ConfigPath 'C:\NonExistent\config.ini' } | Should -Throw

      # Cleanup
      Remove-Item $tempIfas -Force -ErrorAction SilentlyContinue
      Remove-Item $tempSyscat -Force -ErrorAction SilentlyContinue
    }

    It 'Should process with valid parameters when mocked' {
      # Create temporary backup files
      $tempIfas = New-TemporaryFile
      $tempSyscat = New-TemporaryFile

      # Mock all the internal function calls
      Mock -CommandName Add-Module -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Start-Log -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Get-BPERPEnvironmentConfig -ModuleName BPC.DBRefresh -MockWith {
        @{
          SQLInstance = 'TestServer'
          Servers     = @('Server1', 'Server2')
        }
      }
      Mock -CommandName Show-BPERPConfiguration -ModuleName BPC.DBRefresh -MockWith { $true }
      Mock -CommandName Stop-BPERPServices -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Invoke-BPERPDatabaseRestoreFiles -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Set-BPERPDatabaseSettings -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Get-BPERPDatabaseSettings -ModuleName BPC.DBRefresh -MockWith { @{} }
      Mock -CommandName Set-BPERPDatabasePermissions -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Restart-BPERPServers -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Send-BPERPNotification -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -MockWith { }
      Mock -CommandName Stop-Log -ModuleName BPC.DBRefresh -MockWith { }

      # Create a dummy config file
      $tempConfig = New-TemporaryFile
      '[TEST]' | Out-File $tempConfig.FullName

      { Invoke-BPERPDatabaseRestore -BPEnvironment 'TEST' -IfasFilePath $tempIfas.FullName -SyscatFilePath $tempSyscat.FullName -ConfigPath $tempConfig.FullName -SkipConfirmation } | Should -Not -Throw

      # Cleanup config
      Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue

      # Cleanup
      Remove-Item $tempIfas -Force -ErrorAction SilentlyContinue
      Remove-Item $tempSyscat -Force -ErrorAction SilentlyContinue
    }
  }

  Context 'Help documentation' {
    It 'Should have help documentation' {
      $help = Get-Help Invoke-BPERPDatabaseRestore -Full
      $help.Synopsis | Should -Not -BeNullOrEmpty
      $help.Description | Should -Not -BeNullOrEmpty
    }

    It 'Should have parameter help for all parameters' {
      $help = Get-Help Invoke-BPERPDatabaseRestore -Parameter BPEnvironment
      $help.Description | Should -Not -BeNullOrEmpty

      $help = Get-Help Invoke-BPERPDatabaseRestore -Parameter IfasFilePath
      $help.Description | Should -Not -BeNullOrEmpty

      $help = Get-Help Invoke-BPERPDatabaseRestore -Parameter SyscatFilePath
      $help.Description | Should -Not -BeNullOrEmpty
    }

    It 'Should have at least one example' {
      $help = Get-Help Invoke-BPERPDatabaseRestore -Examples
      $help.Examples | Should -Not -BeNullOrEmpty
    }
  }
}
