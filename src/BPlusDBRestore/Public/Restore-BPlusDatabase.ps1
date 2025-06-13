function Restore-BPlusDatabase {
  <#
  .SYNOPSIS
      Restores BusinessPlus databases from backup files
  
  .DESCRIPTION
      Main function that orchestrates the complete BusinessPlus test environment refresh process.
      This includes stopping services, restoring databases, configuring security, and restarting servers.
  
  .PARAMETER BPEnvironment
      The name of the BusinessPlus environment to restore (e.g., TEST, QA, DEV)
  
  .PARAMETER IfasFilePath
      Path to the IFAS database backup file
  
  .PARAMETER SyscatFilePath
      Path to the SYSCAT database backup file
  
  .PARAMETER AspnetFilePath
      Path to the ASPNET database backup file (optional)
  
  .PARAMETER TestingMode
      Enable additional test accounts for testing purposes
  
  .PARAMETER RestoreDashboards
      Copy dashboard files to the environment
  
  .PARAMETER ConfigPath
      Path to the INI configuration file. Defaults to config\hpsBPlusDBRestore.ini
  
  .PARAMETER SkipConfirmation
      Skip the configuration review and confirmation prompt
  
  .EXAMPLE
      Restore-BPlusDatabase -BPEnvironment "TEST" -IfasFilePath "\\backup\ifas.bak" -SyscatFilePath "\\backup\syscat.bak"
  
  .EXAMPLE
      Restore-BPlusDatabase -BPEnvironment "QA" -IfasFilePath $ifas -SyscatFilePath $syscat -AspnetFilePath $aspnet -TestingMode -RestoreDashboards
  #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory = $true)]
    [string]$BPEnvironment,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$IfasFilePath,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_})]
    [string]$SyscatFilePath,
    
    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_})]
    [string]$AspnetFilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestingMode,
    
    [Parameter(Mandatory = $false)]
    [switch]$RestoreDashboards,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation
  )

  begin {
    $ErrorActionPreference = 'Stop'
    $startTime = Get-Date
    
    # Set up logging
    $script:LogPath = Join-Path $PSScriptRoot "..\..\..\..\hpsBPlusDBRestore.log"
    Start-Log -LogPath $script:LogPath -LogName "BPlusDBRestore" -ScriptVersion $script:ModuleVersion
    
    Write-BPlusLog -Message "Starting BusinessPlus Database Restore for environment: $BPEnvironment" -LogPath $script:LogPath
    
    # Load required modules
    try {
      Add-Module -Name 'PSLogging'
      Add-Module -Name 'dbatools'
      Add-Module -Name 'PsIni'
    }
    catch {
      Write-BPlusLog -Message "Failed to load required modules: $_" -Level Error -LogPath $script:LogPath
      throw
    }
    
    # Set default config path if not provided
    if (-not $ConfigPath) {
      $ConfigPath = Join-Path $PSScriptRoot "..\..\..\..\config\hpsBPlusDBRestore.ini"
    }
    
    # Validate config file exists
    if (-not (Test-Path $ConfigPath)) {
      throw "Configuration file not found at: $ConfigPath"
    }
  }

  process {
    try {
      # Load configuration
      Write-BPlusLog -Message "Loading configuration from: $ConfigPath" -LogPath $script:LogPath
      $config = Get-BPlusEnvironmentConfig -Environment $BPEnvironment -ConfigPath $ConfigPath
      
      # Prepare backup files hashtable
      $backupFiles = @{
        IFAS = $IfasFilePath
        SYSCAT = $SyscatFilePath
      }
      if ($AspnetFilePath) {
        $backupFiles.ASPNET = $AspnetFilePath
      }
      
      # Show configuration and get confirmation
      if (-not $SkipConfirmation) {
        $confirmed = Show-BPlusConfiguration -Config $config -BackupFiles $backupFiles -TestingMode $TestingMode -RestoreDashboards $RestoreDashboards
        if (-not $confirmed) {
          Write-BPlusLog -Message "Restore operation cancelled by user" -Level Warning -LogPath $script:LogPath
          return
        }
      }
      
      # Stop BusinessPlus services
      Write-BPlusLog -Message "Stopping BusinessPlus services..." -LogPath $script:LogPath
      Stop-BPlusServices -Config $config
      
      # Get existing database settings
      Write-BPlusLog -Message "Backing up existing database connection settings..." -LogPath $script:LogPath
      $existingSettings = Get-BPlusDatabaseSettings -Config $config
      
      # Restore databases
      Write-BPlusLog -Message "Starting database restore operations..." -LogPath $script:LogPath
      Restore-BPlusDatabaseFiles -Config $config -BackupFiles $backupFiles
      
      # Restore saved settings
      if ($existingSettings) {
        Write-BPlusLog -Message "Restoring database connection settings..." -LogPath $script:LogPath
        Set-BPlusDatabaseSettings -Config $config -Settings $existingSettings
      }
      
      # Set database permissions
      Write-BPlusLog -Message "Configuring database permissions..." -LogPath $script:LogPath
      Set-BPlusDatabasePermissions -Config $config
      
      # Configure BusinessPlus settings
      Write-BPlusLog -Message "Applying post-restore configurations..." -LogPath $script:LogPath
      Set-BPlusConfiguration -Config $config -TestingMode $TestingMode
      
      # Copy dashboard files if requested
      if ($RestoreDashboards) {
        Write-BPlusLog -Message "Copying dashboard files..." -LogPath $script:LogPath
        Copy-BPlusDashboardFiles -Config $config
      }
      
      # Restart servers
      Write-BPlusLog -Message "Restarting BusinessPlus servers..." -LogPath $script:LogPath
      Restart-BPlusServers -Config $config
      
      # Send completion notification
      $endTime = Get-Date
      Write-BPlusLog -Message "Sending completion notification..." -LogPath $script:LogPath
      Send-BPlusNotification -Config $config -BackupFiles $backupFiles -TestingMode $TestingMode -StartTime $startTime -EndTime $endTime
      
      Write-BPlusLog -Message "BusinessPlus Database Restore completed successfully!" -LogPath $script:LogPath
      Write-Host "`nBusinessPlus Database Restore completed successfully!" -ForegroundColor Green
    }
    catch {
      Write-BPlusLog -Message "Error during restore operation: $_" -Level Error -LogPath $script:LogPath
      throw
    }
  }

  end {
    Stop-Log -LogPath $script:LogPath
  }
}