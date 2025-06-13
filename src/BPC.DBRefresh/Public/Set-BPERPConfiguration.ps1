function Set-BPERPConfiguration {
  <#
  .SYNOPSIS
      Applies post-restore configuration settings to BusinessPlus
  
  .DESCRIPTION
      Updates various BusinessPlus settings after database restore including:
      - NUUPAUSY display text with backup date
      - Disables user accounts (except manager codes)
      - Updates email addresses to dummy values
      - Disables non-essential workflows
  
  .PARAMETER Config
      Configuration hashtable containing database and environment information
  
  .PARAMETER TestingMode
      When enabled, preserves additional test accounts
  
  .EXAMPLE
      Set-BPERPConfiguration -Config $config -TestingMode $false
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config,
    
    [Parameter(Mandatory = $false)]
    [bool]$TestingMode = $false
  )

  Write-BPlusLog -Message "Applying post-restore configuration settings" -LogPath $script:LogPath
  
  # Update NUUPAUSY with backup date
  try {
    $backupDate = Get-Date -Format "MM/dd/yyyy"
    $displayText = "Last refreshed from PRODUCTION on $backupDate"
    
    $query = @"
UPDATE NUUPAUSY
SET SYDSCRIP = '$displayText'
WHERE SYPARM = 'SYSYSTEM'
"@
    
    Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    Write-BPlusLog -Message "Updated NUUPAUSY display text" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error updating NUUPAUSY: $_" -Level Warning -LogPath $script:LogPath
  }
  
  # Build manager codes list for SQL IN clause
  $managerCodesList = ($Config.ManagerCodes | ForEach-Object { "'$_'" }) -join ','
  
  # Disable user accounts
  try {
    $query = @"
UPDATE seusrmas
SET ussts = 'I'
WHERE usrid NOT IN ($managerCodesList)
"@
    
    if ($TestingMode) {
      # In testing mode, preserve additional test accounts
      $query += " AND usrid NOT LIKE 'TEST%'"
      Write-BPlusLog -Message "Testing mode: Preserving TEST* accounts" -LogPath $script:LogPath
    }
    
    Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    Write-BPlusLog -Message "Disabled non-manager user accounts" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error disabling user accounts: $_" -Level Warning -LogPath $script:LogPath
  }
  
  # Update email addresses
  try {
    $query = @"
UPDATE seusrmas
SET usemal = 'donotreply@schooldistrict.org'
WHERE usrid NOT IN ($managerCodesList)
  AND usemal IS NOT NULL
  AND usemal <> ''
"@
    
    Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    Write-BPlusLog -Message "Updated email addresses to dummy values" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error updating email addresses: $_" -Level Warning -LogPath $script:LogPath
  }
  
  # Disable workflows
  try {
    # Get list of essential workflows to keep enabled
    $essentialWorkflows = @('POMAINT', 'REQMAINT', 'BIDMAINT')
    $workflowList = ($essentialWorkflows | ForEach-Object { "'$_'" }) -join ','
    
    $query = @"
UPDATE wfwfmast
SET wfenab = 'N'
WHERE wfname NOT IN ($workflowList)
"@
    
    Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    Write-BPlusLog -Message "Disabled non-essential workflows" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error disabling workflows: $_" -Level Warning -LogPath $script:LogPath
  }
  
  # Update ImageNow connection strings if present
  try {
    $query = @"
UPDATE NUUPGDST
SET NUVALUE = REPLACE(NUVALUE, 'PROD', '$($Config.Environment)')
WHERE NUGUID IN (
    'fc0e3ed1-13f5-4e35-8b4d-901e1b7e17fa',
    '8bb973e1-3e14-4f7f-8e22-aafc1e9f7b65'
)
AND NUVALUE LIKE '%PROD%'
"@
    
    Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Database $Config.SYSCATdb -Query $query
    Write-BPlusLog -Message "Updated ImageNow connection strings" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error updating ImageNow settings: $_" -Level Warning -LogPath $script:LogPath
  }
  
  Write-BPlusLog -Message "Post-restore configuration completed" -LogPath $script:LogPath
}