function Set-BPlusDatabaseSettings {
  <#
  .SYNOPSIS
      Restores database connection settings after database restore
  
  .DESCRIPTION
      Updates the NUUPGDST table with the connection settings that were
      backed up before the database restore operation.
  
  .PARAMETER Config
      Configuration hashtable containing database connection information
  
  .PARAMETER Settings
      Array of settings retrieved from Get-BPlusDatabaseSettings
  
  .EXAMPLE
      Set-BPlusDatabaseSettings -Config $config -Settings $savedSettings
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config,
    
    [Parameter(Mandatory = $true)]
    [System.Object[]]$Settings
  )

  Write-BPlusLog -Message "Restoring database connection settings" -LogPath $script:LogPath
  
  foreach ($setting in $Settings) {
    try {
      $query = @"
UPDATE NUUPGDST
SET NUVALUE = '$($setting.NUVALUE)'
WHERE NUGUID = '$($setting.NUGUID)'
"@
      
      Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
      Write-BPlusLog -Message "Restored setting for GUID: $($setting.NUGUID)" -LogPath $script:LogPath
    }
    catch {
      Write-BPlusLog -Message "Error restoring setting $($setting.NUGUID): $_" -Level Warning -LogPath $script:LogPath
    }
  }
  
  Write-BPlusLog -Message "Database connection settings restored" -LogPath $script:LogPath
}