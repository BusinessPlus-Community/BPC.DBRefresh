function Disable-BPlusWorkflows {
    <#
    .SYNOPSIS
        Disables workflows and updates user accounts after database refresh.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER ManagerCodes
        Array of manager codes to keep active.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [string[]]$ManagerCodes,

        [Parameter()]
        [string]$LogFile
    )

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Disabling workflows and updating user accounts"
    }

    try {
        # Format manager codes for SQL IN clause
        $managerCodesFormatted = ($ManagerCodes | ForEach-Object { "'$_'" }) -join ','

        $sqlContent = Get-SqlResourceContent -FileName 'Disable-Workflows.sql' -Parameters @{
            Database     = $Configuration.IfasDatabase
            DummyEmail   = $Configuration.DummyEmail
            ManagerCodes = $managerCodesFormatted
        }

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message "     $sqlContent"
        }

        Invoke-Sqlcmd -Query $sqlContent -Database $Configuration.IfasDatabase `
            -ServerInstance $Configuration.DatabaseServer -ErrorAction Stop

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
            Write-LogInfo -LogPath $LogFile -Message ' '
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to disable workflows: $_"
        }
        throw
    }
}


function Set-NuupausyText {
    <#
    .SYNOPSIS
        Updates the NUUPAUSY text and dashboard URL in the database.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER BackupDate
        The date from the backup header.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [datetime]$BackupDate,

        [Parameter()]
        [string]$LogFile
    )

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Updating NUUPAUSY text and dashboard URL"
    }

    try {
        $nuupausyDate = $BackupDate.AddDays(-1).ToString('yyyyMMdd')
        $fullNuupausyText = "$($Configuration.NuupausyText)$nuupausyDate"

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message "     NUUPAUSY String: $fullNuupausyText"
        }

        $sqlQuery = @"
UPDATE au_audit_mstr SET au_clnm_l = '$fullNuupausyText', au_clnm = '$fullNuupausyText'
UPDATE us_setting SET value = '$($Configuration.DashboardUrl)' WHERE subsystem = '@@'
"@

        Invoke-Sqlcmd -Query $sqlQuery -Database $Configuration.IfasDatabase `
            -ServerInstance $Configuration.DatabaseServer -ErrorAction Stop

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
            Write-LogInfo -LogPath $LogFile -Message ' '
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to update NUUPAUSY: $_"
        }
        throw
    }
}


function Copy-DashboardFiles {
    <#
    .SYNOPSIS
        Copies dashboard files from source to destination.

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

    if (-not $Configuration.DashboardPath) {
        Write-Warning 'No dashboard path configured'
        return
    }

    $paths = $Configuration.DashboardPath -split ':'
    if ($paths.Count -lt 2) {
        throw 'Invalid dashboard path format. Expected "source:destination"'
    }

    $source = $paths[0]
    $destination = $paths[1]

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Restoring dashboard files"
    }

    if (-not (Test-Path -Path $source)) {
        throw "Dashboard source path not found: $source"
    }

    try {
        Copy-Item -Path "$source\*" -Destination "$destination\" -Force -Recurse -PassThru |
            ForEach-Object {
                if ($LogFile) {
                    Out-File -FilePath $LogFile -Append -Encoding UTF8 -InputObject $_.FullName
                }
            }

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
            Write-LogInfo -LogPath $LogFile -Message ' '
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to copy dashboards: $_"
        }
        throw
    }
}
