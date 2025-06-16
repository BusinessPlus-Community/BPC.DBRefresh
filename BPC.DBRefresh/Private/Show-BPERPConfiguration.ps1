function Show-BPERPConfiguration {
    <#
  .SYNOPSIS
      Displays the configuration summary and prompts for confirmation

  .DESCRIPTION
      Shows all configuration settings that will be used for the restore operation
      and asks for user confirmation before proceeding.

  .PARAMETER Config
      The configuration hashtable from Get-BPERPEnvironmentConfig

  .PARAMETER BackupFiles
      Hashtable containing paths to backup files

  .PARAMETER TestingMode
      Whether testing mode is enabled

  .PARAMETER RestoreDashboards
      Whether dashboard restoration is enabled

  .EXAMPLE
      Show-BPERPConfiguration -Config $config -BackupFiles $files -TestingMode $false
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [hashtable]$BackupFiles,

        [Parameter(Mandatory = $false)]
        [bool]$TestingMode = $false,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreDashboards = $false
    )

    Write-Host "`n = ======================= Configuration Review = =======================" -ForegroundColor Cyan
    Write-Host "Environment: $($Config.Environment)" -ForegroundColor Yellow
    Write-Host "Configuration File: $($Config.INIFile)" -ForegroundColor Yellow

    Write-Host "`nDatabase Configuration:" -ForegroundColor Green
    Write-Host "  SQL Instance: $($Config.SQLInstance)"
    Write-Host "  IFAS SQL Instance: $($Config.IfasSQLInstance)"
    Write-Host "  Databases: ASPNET = $($Config.ASPNETdb), IFAS = $($Config.IFASdb), SYSCAT = $($Config.SYSCATdb)"

    Write-Host "`nBackup Files:" -ForegroundColor Green
    foreach ($key in $BackupFiles.Keys) {
        if ($BackupFiles[$key]) {
            Write-Host "  $key : $($BackupFiles[$key])"
        }
    }

    Write-Host "`nTarget Servers:" -ForegroundColor Green
    Write-Host "  Application Servers: $($Config.Servers -join ', ')"
    Write-Host "  SQL Servers: $($Config.SQLServers -join ', ')"

    Write-Host "`nOptions:" -ForegroundColor Green
    Write-Host "  Testing Mode: $TestingMode"
    Write-Host "  Restore Dashboards: $RestoreDashboards"

    Write-Host "`nManager Codes to Preserve:" -ForegroundColor Green
    Write-Host "  $($Config.ManagerCodes -join ', ')"

    Write-Host "=====================================================================" -ForegroundColor Cyan

    # Prompt for confirmation
    $title = "Confirm Restore Operation"
    $message = "Do you want to proceed with the restore operation?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Proceed with restore"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancel operation"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

    $result = $host.ui.PromptForChoice($title, $message, $options, 1)

    return $result -eq 0
}

