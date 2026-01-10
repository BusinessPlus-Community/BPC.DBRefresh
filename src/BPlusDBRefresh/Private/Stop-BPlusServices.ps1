function Stop-BPlusServices {
    <#
    .SYNOPSIS
        Stops BusinessPlus services on specified servers.

    .DESCRIPTION
        Stops BusinessPlus-related services (Workflow, Data Processing, IPC Daemon, IIS)
        on all specified servers in preparation for database refresh.

    .PARAMETER Servers
        Array of server names to stop services on.

    .PARAMETER IpcDaemonName
        The name of the IPC Daemon service.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Servers,

        [Parameter(Mandatory = $true)]
        [string]$IpcDaemonName,

        [Parameter()]
        [string]$LogFile
    )

    $servicesToStop = @('btwfsvc', 'BTNETSVC', $IpcDaemonName, 'W3SVC')
    $results = @()

    foreach ($server in $Servers) {
        foreach ($serviceName in $servicesToStop) {
            try {
                if ($LogFile) {
                    Write-LogInfo -LogPath $LogFile -Message "     Stopping $serviceName on $server"
                }

                $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction SilentlyContinue
                if ($service) {
                    $service.Stop()
                    $service.WaitForStatus('Stopped', (New-TimeSpan -Seconds 60))

                    $results += [PSCustomObject]@{
                        Server  = $server
                        Service = $serviceName
                        Status  = 'Stopped'
                        Error   = $null
                    }
                } else {
                    $results += [PSCustomObject]@{
                        Server  = $server
                        Service = $serviceName
                        Status  = 'NotFound'
                        Error   = $null
                    }
                }
            } catch {
                $results += [PSCustomObject]@{
                    Server  = $server
                    Service = $serviceName
                    Status  = 'Error'
                    Error   = $_.Exception.Message
                }
                Write-Warning "Failed to stop $serviceName on $server`: $_"
            }
        }
    }

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
        Write-LogInfo -LogPath $LogFile -Message ' '
    }

    $results
}


function Start-BPlusServices {
    <#
    .SYNOPSIS
        Starts BusinessPlus services on specified servers.

    .DESCRIPTION
        Starts BusinessPlus-related services after database refresh is complete.

    .PARAMETER Servers
        Array of server names.

    .PARAMETER IpcDaemonName
        The name of the IPC Daemon service.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Servers,

        [Parameter(Mandatory = $true)]
        [string]$IpcDaemonName,

        [Parameter()]
        [string]$LogFile
    )

    # Start in reverse order (IIS first, then app services)
    $servicesToStart = @('W3SVC', $IpcDaemonName, 'BTNETSVC', 'btwfsvc')
    $results = @()

    foreach ($server in $Servers) {
        foreach ($serviceName in $servicesToStart) {
            try {
                if ($LogFile) {
                    Write-LogInfo -LogPath $LogFile -Message "     Starting $serviceName on $server"
                }

                $service = Get-Service -ComputerName $server -Name $serviceName -ErrorAction SilentlyContinue
                if ($service -and $service.Status -ne 'Running') {
                    $service.Start()
                    $service.WaitForStatus('Running', (New-TimeSpan -Seconds 60))

                    $results += [PSCustomObject]@{
                        Server  = $server
                        Service = $serviceName
                        Status  = 'Running'
                        Error   = $null
                    }
                }
            } catch {
                $results += [PSCustomObject]@{
                    Server  = $server
                    Service = $serviceName
                    Status  = 'Error'
                    Error   = $_.Exception.Message
                }
            }
        }
    }

    $results
}
