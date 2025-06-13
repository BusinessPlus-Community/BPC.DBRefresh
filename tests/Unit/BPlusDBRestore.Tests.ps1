BeforeAll {
  # Import the module
  $ModulePath = Join-Path $PSScriptRoot "..\..\src\BPlusDBRestore"
  Import-Module $ModulePath -Force
  
  # Mock external dependencies
  Mock Add-Module {}
  Mock Start-Log {}
  Mock Stop-Log {}
  Mock Write-LogInfo {}
  Mock Write-LogWarning {}
  Mock Write-LogError {}
  Mock Get-IniContent {
    @{
      'TEST' = @{
        'sqlinstance' = 'TESTSQL'
        'ifassqlinstance' = 'TESTIFAS'
        'ASPNETdb' = 'aspnet_test'
        'IFASdb' = 'ifas_test'
        'SYSCATdb' = 'syscat_test'
        'serverlist' = 'SERVER1,SERVER2'
        'sqlserverlist' = 'SQLSERVER1'
        'bplusservice' = 'BusinessPlus'
        'imagenowservice' = 'ImageNow'
      }
      'filepaths' = @{
        'datafilepath' = 'D:\Data'
        'logfilepath' = 'L:\Logs'
        'imagesfilepath' = 'I:\Images'
        'DashboardSourcePath' = 'D:\Dashboards\Source'
        'DashboardDestinationPath' = 'D:\Dashboards\Dest'
      }
      'smtp' = @{
        'smtpserver' = 'smtp.test.com'
        'smtpfrom' = 'noreply@test.com'
        'smtpto' = 'admin@test.com'
        'smtpport' = '25'
        'smtpusessl' = 'False'
      }
      'usersettings' = @{
        'managercodes' = 'MGR001,MGR002'
      }
      'sqlusermapping' = @{
        'DOMAIN\Service' = 'svc_user'
      }
    }
  }
}

Describe "BPlusDBRestore Module Tests" {
  
  Context "Module Structure" {
    It "Should have a module manifest" {
      $manifestPath = Join-Path $PSScriptRoot "..\..\src\BPlusDBRestore\BPlusDBRestore.psd1"
      Test-Path $manifestPath | Should -Be $true
    }
    
    It "Should have a module file" {
      $modulePath = Join-Path $PSScriptRoot "..\..\src\BPlusDBRestore\BPlusDBRestore.psm1"
      Test-Path $modulePath | Should -Be $true
    }
    
    It "Should export expected functions" {
      $exportedFunctions = Get-Command -Module BPlusDBRestore
      $expectedFunctions = @(
        'Restore-BPlusDatabase'
        'Stop-BPlusServices'
        'Get-BPlusDatabaseSettings'
        'Restore-BPlusDatabaseFiles'
        'Set-BPlusDatabaseSettings'
        'Set-BPlusDatabasePermissions'
        'Set-BPlusConfiguration'
        'Copy-BPlusDashboardFiles'
        'Restart-BPlusServers'
        'Send-BPlusNotification'
      )
      
      foreach ($func in $expectedFunctions) {
        $exportedFunctions.Name | Should -Contain $func
      }
    }
  }
  
  Context "Get-BPlusEnvironmentConfig" {
    BeforeAll {
      # Get access to private function
      InModuleScope BPlusDBRestore {
        $script:GetConfig = Get-Command Get-BPlusEnvironmentConfig
      }
    }
    
    It "Should return configuration hashtable" {
      InModuleScope BPlusDBRestore {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config | Should -BeOfType [hashtable]
        $config.Environment | Should -Be 'TEST'
        $config.SQLInstance | Should -Be 'TESTSQL'
        $config.IFASdb | Should -Be 'ifas_test'
      }
    }
    
    It "Should parse server lists correctly" {
      InModuleScope BPlusDBRestore {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config.Servers | Should -Be @('SERVER1', 'SERVER2')
        $config.SQLServers | Should -Be @('SQLSERVER1')
      }
    }
    
    It "Should parse manager codes correctly" {
      InModuleScope BPlusDBRestore {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config.ManagerCodes | Should -Be @('MGR001', 'MGR002')
      }
    }
  }
  
  Context "Restore-BPlusDatabase Parameters" {
    It "Should have mandatory BPEnvironment parameter" {
      $command = Get-Command Restore-BPlusDatabase
      $param = $command.Parameters['BPEnvironment']
      
      $param.Attributes.Mandatory | Should -Contain $true
    }
    
    It "Should have mandatory IfasFilePath parameter" {
      $command = Get-Command Restore-BPlusDatabase
      $param = $command.Parameters['IfasFilePath']
      
      $param.Attributes.Mandatory | Should -Contain $true
    }
    
    It "Should have optional TestingMode switch" {
      $command = Get-Command Restore-BPlusDatabase
      $param = $command.Parameters['TestingMode']
      
      $param.SwitchParameter | Should -Be $true
      $param.Attributes.Mandatory | Should -Not -Contain $true
    }
  }
}