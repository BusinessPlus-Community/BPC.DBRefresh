function Backup-DatabaseConnectionInfo {
    <#
    .SYNOPSIS
        Backs up database connection configuration before refresh.

    .DESCRIPTION
        Captures the current connection configuration from syscat and ifas databases
        so it can be restored after the database refresh.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER LogFile
        Path to the log file.

    .OUTPUTS
        PSCustomObject containing backed up connection data.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter()]
        [string]$LogFile
    )

    $result = [PSCustomObject]@{
        SyscatData = $null
        IfasData   = $null
        Success    = $false
    }

    try {
        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Querying existing connection values"
        }

        # Query syscat database for connection info
        $syscatQuery = @"
SELECT TOP 1 * FROM bsi_sys_blob
WHERE [category]='CONNECT' AND app='CONNECT' AND [name]='$($Configuration.IfasDatabase)'
"@

        $syscatData = New-Object System.Data.DataTable
        $connection = New-Object System.Data.SqlClient.SqlConnection
        $connection.ConnectionString = $Configuration.ConnectionStrings.Syscat
        $connection.Open()

        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = $syscatQuery
        $reader = $command.ExecuteReader()
        $syscatData.Load($reader)
        $connection.Close()

        $result.SyscatData = $syscatData

        # Query ifas database for hostname settings
        $ifasQuery = @"
SELECT TOP 1 * FROM ifas_data
WHERE [name]='Hostnames' AND [category]='Settings' AND [app]='Admin'
"@

        $ifasData = New-Object System.Data.DataTable
        $connection.ConnectionString = $Configuration.ConnectionStrings.Ifas
        $connection.Open()

        $command.CommandText = $ifasQuery
        $reader = $command.ExecuteReader()
        $ifasData.Load($reader)
        $connection.Close()

        # Remove unique_key column as it will be auto-generated
        if ($ifasData.Columns.Contains('unique_key')) {
            $ifasData.Columns.Remove('unique_key')
        }

        $result.IfasData = $ifasData
        $result.Success = $true

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
            Write-LogInfo -LogPath $LogFile -Message ' '
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to backup connection info: $_"
        }
        throw
    } finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
    }

    $result
}


function Restore-DatabaseConnectionInfo {
    <#
    .SYNOPSIS
        Restores database connection configuration after refresh.

    .DESCRIPTION
        Restores the connection configuration that was backed up before the refresh.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER BackupData
        The backup data from Backup-DatabaseConnectionInfo.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$BackupData,

        [Parameter()]
        [string]$LogFile
    )

    try {
        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Restoring connection information"
        }

        # Restore syscat data
        $deleteSyscatQuery = "DELETE FROM bsi_sys_blob WHERE [category]='CONNECT' AND app='CONNECT' AND [name]='ifas'"
        Invoke-Sqlcmd -Query $deleteSyscatQuery -Database $Configuration.SyscatDatabase -ServerInstance $Configuration.DatabaseServer -ErrorAction Stop

        Write-DbaDbTableData -SqlInstance $Configuration.DatabaseServer -InputObject $BackupData.SyscatData `
            -Database $Configuration.SyscatDatabase -Table 'bsi_sys_blob' -Schema 'dbo' -ErrorAction Stop

        # Restore ifas data
        $deleteIfasQuery = "DELETE FROM ifas_data WHERE [name]='Hostnames' AND [category]='Settings' AND [app]='Admin'"
        Invoke-Sqlcmd -Query $deleteIfasQuery -Database $Configuration.IfasDatabase -ServerInstance $Configuration.DatabaseServer -ErrorAction Stop

        Write-DbaDbTableData -SqlInstance $Configuration.DatabaseServer -InputObject $BackupData.IfasData `
            -Database $Configuration.IfasDatabase -Table 'ifas_data' -Schema 'dbo' -ErrorAction Stop

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
            Write-LogInfo -LogPath $LogFile -Message ' '
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to restore connection info: $_"
        }
        throw
    }
}
