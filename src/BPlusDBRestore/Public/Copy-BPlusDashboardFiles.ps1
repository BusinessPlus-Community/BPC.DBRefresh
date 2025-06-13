function Copy-BPlusDashboardFiles {
  <#
  .SYNOPSIS
      Copies dashboard files to the BusinessPlus environment
  
  .DESCRIPTION
      Copies dashboard files from the source location to the destination
      servers specified in the configuration.
  
  .PARAMETER Config
      Configuration hashtable containing dashboard source and destination paths
  
  .EXAMPLE
      Copy-BPlusDashboardFiles -Config $config
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config
  )

  Write-BPlusLog -Message "Starting dashboard file copy operation" -LogPath $script:LogPath
  
  if (-not $Config.DashboardSourcePath -or -not $Config.DashboardDestinationPath) {
    Write-BPlusLog -Message "Dashboard paths not configured, skipping dashboard copy" -Level Warning -LogPath $script:LogPath
    return
  }
  
  if (-not (Test-Path $Config.DashboardSourcePath)) {
    Write-BPlusLog -Message "Dashboard source path not found: $($Config.DashboardSourcePath)" -Level Warning -LogPath $script:LogPath
    return
  }
  
  foreach ($server in $Config.Servers) {
    try {
      $destinationPath = "\\$server\$($Config.DashboardDestinationPath -replace ':', '$')"
      
      Write-BPlusLog -Message "Copying dashboards to: $destinationPath" -LogPath $script:LogPath
      
      # Create destination directory if it doesn't exist
      if (-not (Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
      }
      
      # Copy files
      $copyParams = @{
        Path = Join-Path $Config.DashboardSourcePath "*"
        Destination = $destinationPath
        Recurse = $true
        Force = $true
        ErrorAction = 'Stop'
      }
      
      Copy-Item @copyParams
      
      Write-BPlusLog -Message "Successfully copied dashboard files to $server" -LogPath $script:LogPath
    }
    catch {
      Write-BPlusLog -Message "Error copying dashboard files to $server : $_" -Level Warning -LogPath $script:LogPath
    }
  }
  
  Write-BPlusLog -Message "Dashboard file copy operation completed" -LogPath $script:LogPath
}