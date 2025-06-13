# Test helper functions for BPC.DBRefresh module tests

function New-TestConfiguration {
  <#
  .SYNOPSIS
      Creates a test configuration hashtable
  
  .DESCRIPTION
      Generates a mock configuration hashtable for use in tests
  
  .EXAMPLE
      $config = New-TestConfiguration
  #>
  [CmdletBinding()]
  param()
  
  @{
    Environment = 'TEST'
    INIFile = 'TestDrive:\test.ini'
    SQLInstance = 'TESTSQL\INSTANCE'
    IfasSQLInstance = 'TESTIFAS\INSTANCE'
    ASPNETdb = 'aspnet_test'
    IFASdb = 'ifas_test'
    SYSCATdb = 'syscat_test'
    Servers = @('TESTSERVER1', 'TESTSERVER2')
    SQLServers = @('TESTSQL')
    DataFilePath = 'D:\SQLData'
    LogFilePath = 'L:\SQLLogs'
    ImagesFilePath = 'I:\Images'
    DashboardSourcePath = 'D:\Dashboard\Source'
    DashboardDestinationPath = 'D:\Dashboard\Dest'
    SMTPServer = 'smtp.test.local'
    SMTPFrom = 'noreply@test.local'
    SMTPTo = 'admin@test.local'
    SMTPPort = 25
    SMTPUseSSL = $false
    ManagerCodes = @('MGR001', 'MGR002', 'MGR003')
    BPlusService = 'BusinessPlus'
    ImageNowService = 'ImageNow'
    UserMappings = @{
      'DOMAIN\svc_bplus' = 'bplus_user'
      'DOMAIN\svc_sql' = 'sql_user'
    }
  }
}

function New-TestBackupFiles {
  <#
  .SYNOPSIS
      Creates test backup file paths
  
  .DESCRIPTION
      Generates a hashtable of mock backup file paths for testing
  
  .PARAMETER IncludeASPNET
      Include ASPNET backup file path
  
  .EXAMPLE
      $files = New-TestBackupFiles -IncludeASPNET
  #>
  [CmdletBinding()]
  param(
    [switch]$IncludeASPNET
  )
  
  $files = @{
    IFAS = 'TestDrive:\Backups\ifas_backup.bak'
    SYSCAT = 'TestDrive:\Backups\syscat_backup.bak'
  }
  
  if ($IncludeASPNET) {
    $files.ASPNET = 'TestDrive:\Backups\aspnet_backup.bak'
  }
  
  # Create mock files
  foreach ($file in $files.Values) {
    New-Item -Path $file -ItemType File -Force | Out-Null
  }
  
  return $files
}

function Assert-MockCalledWithParameter {
  <#
  .SYNOPSIS
      Helper to assert mock was called with specific parameter
  
  .DESCRIPTION
      Validates that a mock was called with expected parameter values
  
  .PARAMETER CommandName
      Name of the mocked command
  
  .PARAMETER ParameterName
      Name of the parameter to check
  
  .PARAMETER ExpectedValue
      Expected value of the parameter
  
  .EXAMPLE
      Assert-MockCalledWithParameter -CommandName 'Write-Host' -ParameterName 'Object' -ExpectedValue 'Test'
  #>
  [CmdletBinding()]
  param(
    [string]$CommandName,
    [string]$ParameterName,
    $ExpectedValue
  )
  
  Should -Invoke $CommandName -ParameterFilter {
    $PSBoundParameters[$ParameterName] -eq $ExpectedValue
  }
}

Export-ModuleMember -Function @(
  'New-TestConfiguration'
  'New-TestBackupFiles'
  'Assert-MockCalledWithParameter'
)