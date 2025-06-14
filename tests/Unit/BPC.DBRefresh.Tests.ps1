BeforeAll {
  # Import required modules first
  Import-Module PSLogging -ErrorAction SilentlyContinue
  Import-Module dbatools -ErrorAction SilentlyContinue
  Import-Module PsIni -ErrorAction SilentlyContinue
  
  # Import the module
  $ModulePath = Join-Path $PSScriptRoot "..\..\src\BPC.DBRefresh"
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

Describe "BPC.DBRefresh Module Tests" {
  
  Context "Module Structure" {
    It "Should have a module manifest" {
      $manifestPath = Join-Path $PSScriptRoot "..\..\src\BPC.DBRefresh\BPC.DBRefresh.psd1"
      Test-Path $manifestPath | Should -Be $true
    }
    
    It "Should have a module file" {
      $modulePath = Join-Path $PSScriptRoot "..\..\src\BPC.DBRefresh\BPC.DBRefresh.psm1"
      Test-Path $modulePath | Should -Be $true
    }
    
    It "Should export expected functions" {
      $exportedFunctions = Get-Command -Module BPC.DBRefresh
      $expectedFunctions = @(
        'Invoke-BPERPDatabaseRestore'
        'Stop-BPERPServices'
        'Get-BPERPDatabaseSettings'
        'Invoke-BPERPDatabaseRestoreFiles'
        'Set-BPERPDatabaseSettings'
        'Set-BPERPDatabasePermissions'
        'Set-BPERPConfiguration'
        'Copy-BPERPDashboardFiles'
        'Restart-BPERPServers'
        'Send-BPERPNotification'
      )
      
      foreach ($func in $expectedFunctions) {
        $exportedFunctions.Name | Should -Contain $func
      }
    }
  }
  
  Context "Get-BPlusEnvironmentConfig" {
    BeforeAll {
      # Get access to private function
      InModuleScope BPC.DBRefresh {
        $script:GetConfig = Get-Command Get-BPlusEnvironmentConfig
      }
    }
    
    It "Should return configuration hashtable" {
      InModuleScope BPC.DBRefresh {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config | Should -BeOfType [hashtable]
        $config.Environment | Should -Be 'TEST'
        $config.SQLInstance | Should -Be 'TESTSQL'
        $config.IFASdb | Should -Be 'ifas_test'
      }
    }
    
    It "Should parse server lists correctly" {
      InModuleScope BPC.DBRefresh {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config.Servers | Should -Be @('SERVER1', 'SERVER2')
        $config.SQLServers | Should -Be @('SQLSERVER1')
      }
    }
    
    It "Should parse manager codes correctly" {
      InModuleScope BPC.DBRefresh {
        $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'TestDrive:\test.ini'
        
        $config.ManagerCodes | Should -Be @('MGR001', 'MGR002')
      }
    }
  }
  
  Context "Invoke-BPERPDatabaseRestore Parameters" {
    It "Should have mandatory BPEnvironment parameter" {
      $command = Get-Command Invoke-BPERPDatabaseRestore
      $param = $command.Parameters['BPEnvironment']
      
      $param.Attributes.Mandatory | Should -Contain $true
    }
    
    It "Should have mandatory IfasFilePath parameter" {
      $command = Get-Command Invoke-BPERPDatabaseRestore
      $param = $command.Parameters['IfasFilePath']
      
      $param.Attributes.Mandatory | Should -Contain $true
    }
    
    It "Should have optional TestingMode switch" {
      $command = Get-Command Invoke-BPERPDatabaseRestore
      $param = $command.Parameters['TestingMode']
      
      $param.SwitchParameter | Should -Be $true
      $param.Attributes.Mandatory | Should -Not -Contain $true
    }
  }
}