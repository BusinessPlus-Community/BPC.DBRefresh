function Set-BPERPDatabaseSettings {
    <#
  .SYNOPSIS
      Restores database connection settings after database restore

  .DESCRIPTION
      Updates the NUUPGDST table with the connection settings that were
      backed up before the database restore operation.

  .PARAMETER Config
      Configuration hashtable containing database connection information

  .PARAMETER Settings
      Array of settings retrieved from Get-BPERPDatabaseSettings

  .EXAMPLE
      Set-BPERPDatabaseSettings -Config $config -Settings $savedSettings
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [System.Object[]]$Settings
    )

    Write-BPERPLog -Message "Restoring database connection settings" -LogPath $script:LogPath

    foreach ($setting in $Settings) {
        try {
            $query = @"
UPDATE NUUPGDST
SET NUVALUE = '$($setting.NUVALUE)'
WHERE NUGUID = '$($setting.NUGUID)'
"@

            Invoke-DbaQuery -SqlInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
            Write-BPERPLog -Message "Restored setting for GUID: $($setting.NUGUID)" -LogPath $script:LogPath
        } catch {
            Write-BPERPLog -Message "Error restoring setting $($setting.NUGUID): $_" -Level Warning -LogPath $script:LogPath
        }
    }

    Write-BPERPLog -Message "Database connection settings restored" -LogPath $script:LogPath
}

