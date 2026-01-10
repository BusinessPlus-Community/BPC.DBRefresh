function Build-FileMapping {
    <#
    .SYNOPSIS
        Builds a file mapping hashtable for database restore operations.

    .DESCRIPTION
        Parses the file drive configuration strings and builds a hashtable
        mapping logical file names to physical paths for use with Restore-DbaDatabase.

    .PARAMETER FileDrives
        Array of file drive configuration strings in format "LogicalName:DriveType:FileName".

    .PARAMETER FilePaths
        Object containing Data, Log, and Images path settings.

    .OUTPUTS
        Hashtable mapping logical names to physical paths.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FileDrives,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FilePaths
    )

    $fileMapping = @{}

    foreach ($fileDrive in $FileDrives) {
        $parts = $fileDrive.Split(':')
        if ($parts.Count -ge 3) {
            $logicalName = $parts[0].Trim()
            $driveType = $parts[1].Trim()
            $fileName = $parts[2].Trim()

            $basePath = switch ($driveType) {
                'Data'   { $FilePaths.Data }
                'Log'    { $FilePaths.Log }
                'Images' { $FilePaths.Images }
                default  { $FilePaths.Data }
            }

            # Use string concatenation instead of Join-Path for Windows path compatibility on Linux
            if ($basePath -and $fileName) {
                $separator = if ($basePath -match '^[A-Za-z]:') { '\' } else { [System.IO.Path]::DirectorySeparatorChar }
                $fullPath = $basePath.TrimEnd('\', '/') + $separator + $fileName
                $fileMapping[$logicalName] = $fullPath
            }
        }
    }

    $fileMapping
}


function Restore-BPlusDatabase {
    <#
    .SYNOPSIS
        Restores a BusinessPlus database from backup.

    .DESCRIPTION
        Restores the specified database (IFAS, Syscat, or ASP.NET) from a backup file
        using the file mapping configuration from the INI file.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER DatabaseType
        The type of database: Ifas, Syscat, or Aspnet.

    .PARAMETER BackupPath
        Path to the backup file.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Ifas', 'Syscat', 'Aspnet')]
        [string]$DatabaseType,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$BackupPath,

        [Parameter()]
        [string]$LogFile
    )

    # Get database name and file drives based on type
    $databaseName = switch ($DatabaseType) {
        'Ifas'   { $Configuration.IfasDatabase }
        'Syscat' { $Configuration.SyscatDatabase }
        'Aspnet' { $Configuration.AspnetDatabase }
    }

    $fileDrives = switch ($DatabaseType) {
        'Ifas'   { $Configuration.FileDrives.Ifas }
        'Syscat' { $Configuration.FileDrives.Syscat }
        'Aspnet' { $Configuration.FileDrives.Aspnet }
    }

    if (-not $databaseName) {
        Write-Warning "No database configured for type: $DatabaseType"
        return
    }

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "     $(Get-Date -Format 'G') - Restoring $databaseName database"
    }

    try {
        # Build file mapping
        $fileMapping = Build-FileMapping -FileDrives $fileDrives -FilePaths $Configuration.FilePaths

        if ($PSCmdlet.ShouldProcess($databaseName, 'Restore database')) {
            # Restore database using dbatools
            $restoreResult = Restore-DbaDatabase -SqlInstance $Configuration.DatabaseServer `
                -Path $BackupPath `
                -DatabaseName $databaseName `
                -FileMapping $fileMapping `
                -WithReplace `
                -ErrorAction Stop

            if ($LogFile) {
                $restoreResult | Out-File -FilePath $LogFile -Append -Encoding UTF8
                Write-LogInfo -LogPath $LogFile -Message "     $(Get-Date -Format 'G') - $databaseName restore complete"
            }

            $restoreResult
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to restore $databaseName`: $_"
        }
        throw
    }
}
