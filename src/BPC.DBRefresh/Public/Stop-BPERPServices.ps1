function Stop-BPERPServices {
  <#
  .SYNOPSIS
      Stops BusinessPlus services on specified servers
  
  .DESCRIPTION
      Stops the BusinessPlus and ImageNow services on all servers in the environment.
      Waits for services to fully stop before returning.
  
  .PARAMETER Config
      Configuration hashtable containing server lists and service names
  
  .EXAMPLE
      Stop-BPERPServices -Config $config
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config
  )

  Write-BPlusLog -Message "Stopping services on servers: $($Config.Servers -join ', ')" -LogPath $script:LogPath

  foreach ($server in $Config.Servers) {
    Write-BPlusLog -Message "Processing server: $server" -LogPath $script:LogPath
    
    # Stop BusinessPlus service
    if ($Config.BPlusService) {
      try {
        $service = Get-Service -ComputerName $server -Name $Config.BPlusService -ErrorAction SilentlyContinue
        if ($service) {
          if ($service.Status -eq 'Running') {
            Write-BPlusLog -Message "Stopping $($Config.BPlusService) on $server" -LogPath $script:LogPath
            Stop-Service -InputObject $service -Force
            $service.WaitForStatus('Stopped', '00:02:00')
          }
          else {
            Write-BPlusLog -Message "$($Config.BPlusService) is already stopped on $server" -LogPath $script:LogPath
          }
        }
      }
      catch {
        Write-BPlusLog -Message "Error stopping $($Config.BPlusService) on $server : $_" -Level Warning -LogPath $script:LogPath
      }
    }
    
    # Stop ImageNow service
    if ($Config.ImageNowService) {
      try {
        $service = Get-Service -ComputerName $server -Name $Config.ImageNowService -ErrorAction SilentlyContinue
        if ($service) {
          if ($service.Status -eq 'Running') {
            Write-BPlusLog -Message "Stopping $($Config.ImageNowService) on $server" -LogPath $script:LogPath
            Stop-Service -InputObject $service -Force
            $service.WaitForStatus('Stopped', '00:02:00')
          }
          else {
            Write-BPlusLog -Message "$($Config.ImageNowService) is already stopped on $server" -LogPath $script:LogPath
          }
        }
      }
      catch {
        Write-BPlusLog -Message "Error stopping $($Config.ImageNowService) on $server : $_" -Level Warning -LogPath $script:LogPath
      }
    }
  }
  
  Write-BPlusLog -Message "All services stopped successfully" -LogPath $script:LogPath
}