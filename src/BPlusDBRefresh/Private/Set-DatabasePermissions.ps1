function Set-DatabasePermissions {
    <#
    .SYNOPSIS
        Configures database permissions after restore.

    .DESCRIPTION
        Executes SQL scripts to configure security permissions on restored databases,
        replacing production accounts with test environment accounts.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter()]
        [string]$LogFile
    )

    $databases = @(
        @{ Type = 'Aspnet'; Database = $Configuration.AspnetDatabase; SqlFile = 'Set-AspnetPermissions.sql' },
        @{ Type = 'Ifas'; Database = $Configuration.IfasDatabase; SqlFile = 'Set-IfasPermissions.sql' },
        @{ Type = 'Syscat'; Database = $Configuration.SyscatDatabase; SqlFile = 'Set-SyscatPermissions.sql' }
    )

    foreach ($db in $databases) {
        if (-not $db.Database) { continue }

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message "     Setting permissions on $($db.Database) database"
        }

        try {
            $sqlContent = Get-SqlResourceContent -FileName $db.SqlFile -Parameters @{
                Database         = $db.Database
                IusrSource       = $Configuration.Security.IusrSource
                IusrDestination  = $Configuration.Security.IusrDestination
                AdminSource      = $Configuration.Security.AdminSource
                AdminDestination = $Configuration.Security.AdminDestination
                DboSource        = $Configuration.Security.DboSource
                DboDestination   = $Configuration.Security.DboDestination
            }

            if ($LogFile) {
                Write-LogInfo -LogPath $LogFile -Message "     $sqlContent"
            }

            Invoke-Sqlcmd -Query $sqlContent -Database $db.Database -ServerInstance $Configuration.DatabaseServer -ErrorAction Stop

            if ($LogFile) {
                Write-LogInfo -LogPath $LogFile -Message '     Completed Successfully.'
            }

        } catch {
            if ($LogFile) {
                Write-LogError -LogPath $LogFile -Message "Failed to set permissions on $($db.Database): $_"
            }
            throw
        }
    }

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
        Write-LogInfo -LogPath $LogFile -Message ' '
    }
}
