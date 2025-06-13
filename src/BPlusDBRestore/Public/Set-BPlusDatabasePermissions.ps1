function Set-BPlusDatabasePermissions {
  <#
  .SYNOPSIS
      Sets database permissions and security configurations
  
  .DESCRIPTION
      Configures database ownership, user mappings, permissions, and recovery models
      for the restored databases.
  
  .PARAMETER Config
      Configuration hashtable containing database and user mapping information
  
  .EXAMPLE
      Set-BPlusDatabasePermissions -Config $config
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config
  )

  Write-BPlusLog -Message "Setting database permissions and security" -LogPath $script:LogPath
  
  # Set database ownership
  $databases = @($Config.SYSCATdb, $Config.IFASdb)
  if ($Config.ASPNETdb) {
    $databases += $Config.ASPNETdb
  }
  
  foreach ($database in $databases) {
    try {
      $instance = if ($database -eq $Config.IFASdb) { $Config.IfasSQLInstance } else { $Config.SQLInstance }
      
      # Set database owner to sa
      $query = "ALTER AUTHORIZATION ON DATABASE::[$database] TO [sa]"
      Invoke-Sqlcmd -ServerInstance $instance -Query $query
      Write-BPlusLog -Message "Set database owner for $database to sa" -LogPath $script:LogPath
      
      # Set recovery model to SIMPLE
      $query = "ALTER DATABASE [$database] SET RECOVERY SIMPLE"
      Invoke-Sqlcmd -ServerInstance $instance -Query $query
      Write-BPlusLog -Message "Set recovery model for $database to SIMPLE" -LogPath $script:LogPath
      
      # Update compatibility level if needed
      $query = @"
IF (SELECT compatibility_level FROM sys.databases WHERE name = '$database') < 100
BEGIN
    ALTER DATABASE [$database] SET COMPATIBILITY_LEVEL = 100
END
"@
      Invoke-Sqlcmd -ServerInstance $instance -Query $query
      Write-BPlusLog -Message "Updated compatibility level for $database" -LogPath $script:LogPath
    }
    catch {
      Write-BPlusLog -Message "Error setting permissions for $database : $_" -Level Warning -LogPath $script:LogPath
    }
  }
  
  # Configure user mappings
  Write-BPlusLog -Message "Configuring SQL user mappings" -LogPath $script:LogPath
  
  foreach ($mapping in $Config.UserMappings.GetEnumerator()) {
    try {
      $loginName = $mapping.Key
      $userName = $mapping.Value
      
      # Check if login exists
      $checkLogin = "SELECT COUNT(*) as Count FROM sys.server_principals WHERE name = '$loginName'"
      $loginExists = (Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Query $checkLogin).Count
      
      if ($loginExists -eq 0) {
        Write-BPlusLog -Message "Creating login: $loginName" -LogPath $script:LogPath
        $createLogin = "CREATE LOGIN [$loginName] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
        Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Query $createLogin
      }
      
      # Map user in SYSCAT database
      $mapUser = @"
USE [$($Config.SYSCATdb)]
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$userName')
    CREATE USER [$userName] FOR LOGIN [$loginName]
ALTER USER [$userName] WITH LOGIN = [$loginName]
EXEC sp_addrolemember 'db_owner', '$userName'
"@
      Invoke-Sqlcmd -ServerInstance $Config.SQLInstance -Query $mapUser
      Write-BPlusLog -Message "Mapped user $userName in SYSCAT database" -LogPath $script:LogPath
      
      # Map user in IFAS database
      $mapUser = @"
USE [$($Config.IFASdb)]
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '$userName')
    CREATE USER [$userName] FOR LOGIN [$loginName]
ALTER USER [$userName] WITH LOGIN = [$loginName]
EXEC sp_addrolemember 'db_owner', '$userName'
"@
      Invoke-Sqlcmd -ServerInstance $Config.IfasSQLInstance -Query $mapUser
      Write-BPlusLog -Message "Mapped user $userName in IFAS database" -LogPath $script:LogPath
    }
    catch {
      Write-BPlusLog -Message "Error mapping user $($mapping.Key): $_" -Level Warning -LogPath $script:LogPath
    }
  }
  
  Write-BPlusLog -Message "Database permissions configuration completed" -LogPath $script:LogPath
}