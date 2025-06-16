function Restart-BPERPServers {
    <#
  .SYNOPSIS
      Restarts all BusinessPlus servers in the environment

  .DESCRIPTION
      Initiates a restart of all servers to ensure services start properly
      with the newly restored databases.

  .PARAMETER Config
      Configuration hashtable containing server lists

  .EXAMPLE
      Restart-BPERPServers -Config $config
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    Write-BPERPLog -Message "Initiating server restart for all BusinessPlus servers" -LogPath $script:LogPath

    $allServers = @($Config.Servers) + @($Config.SQLServers) | Select-Object -Unique

    foreach ($server in $allServers) {
        try {
            Write-BPERPLog -Message "Scheduling restart for server: $server" -LogPath $script:LogPath

            # Schedule restart in 60 seconds to allow time for script to complete
            $restartTime = (Get-Date).AddSeconds(60)
            $timeString = $restartTime.ToString("HH:mm")

            # Use shutdown command to schedule restart
            $shutdownParams = @{
                ComputerName = $server
                ArgumentList = "/r /t 60 /c `"BusinessPlus Database Restore - Scheduled restart`" /f"
            }

            Invoke-Command -ComputerName $server -ScriptBlock {
                param($shutdownArgs)
                Start-Process -FilePath "shutdown.exe" -ArgumentList $shutdownArgs -NoNewWindow
            } -ArgumentList $shutdownParams.ArgumentList

            Write-BPERPLog -Message "Restart scheduled for $server at $timeString" -LogPath $script:LogPath
        } catch {
            Write-BPERPLog -Message "Error scheduling restart for $server : $_" -Level Warning -LogPath $script:LogPath

            # Try alternative restart method
            try {
                Restart-Computer -ComputerName $server -Force -AsJob
                Write-BPERPLog -Message "Initiated immediate restart for $server" -LogPath $script:LogPath
            } catch {
                Write-BPERPLog -Message "Failed to restart $server : $_" -Level Error -LogPath $script:LogPath
            }
        }
    }

    Write-BPERPLog -Message "Server restart commands issued for all servers" -LogPath $script:LogPath
    Write-BPERPLog -Message "Servers will restart in approximately 60 seconds" -LogPath $script:LogPath
}

