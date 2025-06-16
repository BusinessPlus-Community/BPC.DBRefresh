function Invoke-BPERPDatabaseRestoreFiles {
    <#
  .SYNOPSIS
      Restores BusinessPlus database files from backups

  .DESCRIPTION
      Performs the actual database restore operations for ASPNET, SYSCAT, and IFAS databases.
      Uses dbatools for reliable database restoration with proper file relocation.

  .PARAMETER Config
      Configuration hashtable containing database and file path information

  .PARAMETER BackupFiles
      Hashtable containing paths to backup files (ASPNET, SYSCAT, IFAS)

  .EXAMPLE
      Invoke-BPERPDatabaseRestoreFiles -Config $config -BackupFiles @{IFAS = 'C:\backup\ifas.bak'; SYSCAT = 'C:\backup\syscat.bak'}
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [hashtable]$BackupFiles
    )

    # Restore ASPNET database if backup provided
    if ($BackupFiles.ASPNET) {
        Write-BPERPLog -Message "Restoring ASPNET database from: $($BackupFiles.ASPNET)" -LogPath $script:LogPath

        $fileMapping = @{
            'aspnetdb'     = Join-Path $Config.DataFilePath "$($Config.ASPNETdb).mdf"
            'aspnetdb_log' = Join-Path $Config.LogFilePath "$($Config.ASPNETdb)_log.ldf"
        }

        try {
            $restoreParams = @{
                SqlInstance = $Config.SQLInstance
                Database = $Config.ASPNETdb
                BackupFile = $BackupFiles.ASPNET
                FileMapping = $fileMapping
                WithReplace = $true
                EnableException = $true
            }

            Restore-DbaDatabase @restoreParams
            Write-BPERPLog -Message "ASPNET database restored successfully" -LogPath $script:LogPath
        } catch {
            Write-BPERPLog -Message "Error restoring ASPNET database: $_" -Level Error -LogPath $script:LogPath
            throw
        }
    }

    # Restore SYSCAT database
    Write-BPERPLog -Message "Restoring SYSCAT database from: $($BackupFiles.SYSCAT)" -LogPath $script:LogPath

    $fileMapping = @{
        'NUCATSQL_Data' = Join-Path $Config.DataFilePath "$($Config.SYSCATdb)_DATA.mdf"
        'NUCATSQL_Log'  = Join-Path $Config.LogFilePath "$($Config.SYSCATdb)_Log.ldf"
        'NUCATSQL_MMO'  = Join-Path $Config.DataFilePath "$($Config.SYSCATdb)_MMO_DATA.ndf"
    }

    try {
        $restoreParams = @{
            SqlInstance = $Config.SQLInstance
            Database = $Config.SYSCATdb
            BackupFile = $BackupFiles.SYSCAT
            FileMapping = $fileMapping
            WithReplace = $true
            EnableException = $true
        }

        Restore-DbaDatabase @restoreParams
        Write-BPERPLog -Message "SYSCAT database restored successfully" -LogPath $script:LogPath
    } catch {
        Write-BPERPLog -Message "Error restoring SYSCAT database: $_" -Level Error -LogPath $script:LogPath
        throw
    }

    # Restore IFAS database
    Write-BPERPLog -Message "Restoring IFAS database from: $($BackupFiles.IFAS)" -LogPath $script:LogPath

    $fileMapping = @{
        'IFASSQL_Data'           = Join-Path $Config.DataFilePath "$($Config.IFASdb)_DATA.mdf"
        'IFASSQL_Log'            = Join-Path $Config.LogFilePath "$($Config.IFASdb)_Log.ldf"
        'FG01IFASSQL_ARC01_Data' = Join-Path $Config.DataFilePath "$($Config.IFASdb)_ARC01_DATA.ndf"
        'FG01IFASSQL_LRG01_Data' = Join-Path $Config.DataFilePath "$($Config.IFASdb)_LRG01_DATA.ndf"
        'FG01IFASSQL_REG01_Data' = Join-Path $Config.DataFilePath "$($Config.IFASdb)_REG01_DATA.ndf"
        'IFASSQL_MMO'            = Join-Path $Config.DataFilePath "$($Config.IFASdb)_MMO_DATA.ndf"
    }

    try {
        $restoreParams = @{
            SqlInstance = $Config.IfasSQLInstance
            Database = $Config.IFASdb
            BackupFile = $BackupFiles.IFAS
            FileMapping = $fileMapping
            WithReplace = $true
            EnableException = $true
        }

        Restore-DbaDatabase @restoreParams
        Write-BPERPLog -Message "IFAS database restored successfully" -LogPath $script:LogPath
    } catch {
        Write-BPERPLog -Message "Error restoring IFAS database: $_" -Level Error -LogPath $script:LogPath
        throw
    }

    Write-BPERPLog -Message "All database restores completed successfully" -LogPath $script:LogPath
}

