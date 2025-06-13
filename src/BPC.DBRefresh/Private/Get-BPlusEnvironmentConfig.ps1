function Get-BPlusEnvironmentConfig {
  <#
  .SYNOPSIS
      Reads and parses the BusinessPlus environment configuration from INI file
  
  .DESCRIPTION
      Loads the configuration INI file and extracts all settings for the specified environment.
      Creates a structured hashtable with all configuration values.
  
  .PARAMETER Environment
      The name of the BusinessPlus environment (e.g., TEST, QA, PROD)
  
  .PARAMETER ConfigPath
      Path to the INI configuration file
  
  .EXAMPLE
      $config = Get-BPlusEnvironmentConfig -Environment 'TEST' -ConfigPath 'C:\config\hpsBPC.DBRefresh.ini'
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$ConfigPath
  )

  Write-Verbose "Loading configuration for environment: $Environment"
  
  # Load INI file
  $iniContent = Get-IniContent -FilePath $ConfigPath
  
  # Validate environment exists in config
  if (-not $iniContent.ContainsKey($Environment)) {
    throw "Environment '$Environment' not found in configuration file"
  }
  
  # Build configuration hashtable
  $config = @{
    Environment = $Environment
    INIFile = $ConfigPath
    
    # SQL Server settings
    SQLInstance = $iniContent[$Environment]['sqlinstance']
    IfasSQLInstance = $iniContent[$Environment]['ifassqlinstance']
    ASPNETdb = $iniContent[$Environment]['ASPNETdb']
    IFASdb = $iniContent[$Environment]['IFASdb']
    SYSCATdb = $iniContent[$Environment]['SYSCATdb']
    
    # Server lists
    Servers = @($iniContent[$Environment]['serverlist'] -split ',\s*')
    SQLServers = @($iniContent[$Environment]['sqlserverlist'] -split ',\s*')
    
    # File paths
    DataFilePath = $iniContent['filepaths']['datafilepath']
    LogFilePath = $iniContent['filepaths']['logfilepath']
    ImagesFilePath = $iniContent['filepaths']['imagesfilepath']
    DashboardSourcePath = $iniContent['filepaths']['DashboardSourcePath']
    DashboardDestinationPath = $iniContent['filepaths']['DashboardDestinationPath']
    
    # SMTP settings
    SMTPServer = $iniContent['smtp']['smtpserver']
    SMTPFrom = $iniContent['smtp']['smtpfrom']
    SMTPTo = $iniContent['smtp']['smtpto']
    SMTPPort = [int]$iniContent['smtp']['smtpport']
    SMTPUseSSL = [bool]($iniContent['smtp']['smtpusessl'] -eq 'True')
    
    # Security settings
    ManagerCodes = @($iniContent['usersettings']['managercodes'] -split ',\s*')
    
    # Services
    BPlusService = $iniContent[$Environment]['bplusservice']
    ImageNowService = $iniContent[$Environment]['imagenowservice']
  }
  
  # Add user mappings
  $config.UserMappings = @{}
  foreach ($key in $iniContent['sqlusermapping'].Keys) {
    $config.UserMappings[$key] = $iniContent['sqlusermapping'][$key]
  }
  
  return $config
}