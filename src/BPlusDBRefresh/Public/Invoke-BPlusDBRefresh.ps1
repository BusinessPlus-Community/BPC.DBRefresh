function Invoke-BPlusDBRefresh {
    <#
    .SYNOPSIS
        Performs a complete database refresh for a BusinessPlus test environment.

    .DESCRIPTION
        This function automates the process of refreshing BusinessPlus test environment databases.
        It performs the following operations in sequence:
        1. Loads required PowerShell modules
        2. Parses environment configuration from JSON file
        3. Displays configuration for user review and confirmation
        4. Stops BusinessPlus services on target servers
        5. Backs up existing database connection configuration
        6. Restores databases from backup files
        7. Restores environment connection information
        8. Configures database permissions
        9. Disables workflows and non-tester user accounts
        10. Updates NUUPAUSY text and dashboard URL
        11. Optionally restores dashboard files
        12. Reboots environment servers
        13. Sends completion notification email

    .PARAMETER BPEnvironment
        The name of the BusinessPlus environment to refresh (e.g., TEST1, TEST2).
        This must match an environment key in the JSON configuration file.

    .PARAMETER AspnetFilePath
        The path to the ASP.NET database backup file (.bak).
        Optional - only required if the environment uses an ASP.NET database.

    .PARAMETER IfasFilePath
        The path to the IFAS/BusinessPlus database backup file (.bak).
        This parameter is mandatory.

    .PARAMETER SyscatFilePath
        The path to the Syscat database backup file (.bak).
        This parameter is mandatory.

    .PARAMETER TestingMode
        When specified, enables additional user accounts for testing purposes
        based on the TestingMode manager codes in the configuration file.

    .PARAMETER RestoreDashboards
        When specified, copies dashboard files from the source location
        to the destination specified in the configuration file.

    .PARAMETER ConfigurationPath
        The path to the JSON configuration file.
        Defaults to 'bpcBPlusDBRefresh.json' in the script directory,
        falling back to 'bpcBPlusDBRefresh.ini' for legacy compatibility.

    .EXAMPLE
        Invoke-BPlusDBRefresh -BPEnvironment 'TEST1' -IfasFilePath '\\backup\ifas.bak' -SyscatFilePath '\\backup\syscat.bak'

        Performs a basic database refresh of the TEST1 environment.

    .EXAMPLE
        Invoke-BPlusDBRefresh -BPEnvironment 'TEST1' -IfasFilePath '\\backup\ifas.bak' -SyscatFilePath '\\backup\syscat.bak' -TestingMode

        Performs a database refresh with additional test accounts enabled.

    .EXAMPLE
        Invoke-BPlusDBRefresh -BPEnvironment 'TEST1' -IfasFilePath '\\backup\ifas.bak' -SyscatFilePath '\\backup\syscat.bak' -RestoreDashboards -WhatIf

        Shows what would happen during a refresh with dashboard restoration without making changes.

    .OUTPUTS
        PSCustomObject
        Returns an object containing the refresh operation results including:
        - Environment: The environment name
        - StartTime: When the refresh started
        - EndTime: When the refresh completed
        - Success: Whether the operation completed successfully
        - DatabasesRestored: List of restored databases
        - ServersRebooted: List of rebooted servers
        - Errors: Any errors encountered during the process

    .NOTES
        Version: 2.0.0
        Author: Zachary V. Birge
        Requires: PSLogging, dbatools modules
        Requires: MailKit/MimeKit for email notifications

    .LINK
        Get-BPlusConfiguration
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$BPEnvironment,

        [Parameter(Position = 1)]
        [ValidateScript({ Test-Path -Path $_ -IsValid })]
        [string]$AspnetFilePath,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -IsValid })]
        [string]$IfasFilePath,

        [Parameter(Mandatory = $true, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -IsValid })]
        [string]$SyscatFilePath,

        [Parameter()]
        [switch]$TestingMode,

        [Parameter()]
        [switch]$RestoreDashboards,

        [Parameter()]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$ConfigurationPath
    )

    begin {
        # Initialize result object
        $result = [PSCustomObject]@{
            Environment       = $BPEnvironment
            StartTime         = Get-Date
            EndTime           = $null
            Success           = $false
            DatabasesRestored = @()
            ServersRebooted   = @()
            Errors            = @()
        }

        # Set error action for proper error handling
        $ErrorActionPreference = 'Stop'

        # Determine configuration file path (try JSON first, fall back to INI)
        if (-not $ConfigurationPath) {
            $ConfigurationPath = Join-Path -Path $script:ModuleRoot -ChildPath '..\..\..\bpcBPlusDBRefresh.json'
            if (-not (Test-Path -Path $ConfigurationPath)) {
                $ConfigurationPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\bpcBPlusDBRefresh.json'
            }
            if (-not (Test-Path -Path $ConfigurationPath)) {
                $ConfigurationPath = Join-Path -Path $script:ModuleRoot -ChildPath '..\..\..\bpcBPlusDBRefresh.ini'
                if (-not (Test-Path -Path $ConfigurationPath)) {
                    $ConfigurationPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\bpcBPlusDBRefresh.ini'
                }
            }
        }

        # Initialize logging
        $logPath = Split-Path -Path $ConfigurationPath -Parent
        $logName = 'bpcBPlusDBRefresh.log'
        $logFile = Join-Path -Path $logPath -ChildPath $logName

        try {
            # Import required modules
            Import-RequiredModule -ModuleName 'PSLogging'
            Import-RequiredModule -ModuleName 'dbatools'
        } catch {
            $result.Errors += "Failed to import required modules: $_"
            throw
        }

        # Start logging
        try {
            Start-Log -LogPath $logPath -LogName $logName -ScriptVersion '2.0.0'
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Starting refresh of $BPEnvironment environment"
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Requested by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
        } catch {
            Write-Warning "Failed to initialize logging: $_"
        }
    }

    process {
        try {
            # Step 1: Load and validate configuration
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Loading configuration from $ConfigurationPath"
            $config = Get-BPlusConfiguration -Path $ConfigurationPath -Environment $BPEnvironment

            # Step 2: Display configuration and request confirmation
            Show-ConfigurationReview -Configuration $config -IfasFilePath $IfasFilePath -SyscatFilePath $SyscatFilePath `
                -AspnetFilePath $AspnetFilePath -TestingMode:$TestingMode -RestoreDashboards:$RestoreDashboards

            if (-not (Request-UserConfirmation -Environment $BPEnvironment)) {
                Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - User cancelled the operation"
                $result.Errors += "Operation cancelled by user"
                return $result
            }

            # Step 3: Stop BusinessPlus services
            if ($PSCmdlet.ShouldProcess($config.Servers -join ', ', 'Stop BusinessPlus services')) {
                Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Stopping BusinessPlus services"
                Stop-BPlusServices -Servers $config.Servers -IpcDaemonName $config.IpcDaemon -LogFile $logFile
            }

            # Step 4: Backup existing database connection info
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Backing up database connection information"
            $connectionBackup = Backup-DatabaseConnectionInfo -Configuration $config -LogFile $logFile

            # Step 5: Restore databases
            if ($PSCmdlet.ShouldProcess($config.IfasDatabase, 'Restore IFAS database')) {
                Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Restoring databases"

                # Restore IFAS database
                Restore-BPlusDatabase -Configuration $config -DatabaseType 'Ifas' -BackupPath $IfasFilePath -LogFile $logFile
                $result.DatabasesRestored += $config.IfasDatabase

                # Restore Syscat database
                Restore-BPlusDatabase -Configuration $config -DatabaseType 'Syscat' -BackupPath $SyscatFilePath -LogFile $logFile
                $result.DatabasesRestored += $config.SyscatDatabase

                # Restore ASP.NET database if specified
                if ($AspnetFilePath -and $config.AspnetDatabase) {
                    Restore-BPlusDatabase -Configuration $config -DatabaseType 'Aspnet' -BackupPath $AspnetFilePath -LogFile $logFile
                    $result.DatabasesRestored += $config.AspnetDatabase
                }
            }

            # Step 6: Restore environment connection info
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Restoring database connection information"
            Restore-DatabaseConnectionInfo -Configuration $config -BackupData $connectionBackup -LogFile $logFile

            # Step 7: Set database permissions
            if ($PSCmdlet.ShouldProcess('Database permissions', 'Configure security')) {
                Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Configuring database permissions"
                Set-DatabasePermissions -Configuration $config -LogFile $logFile
            }

            # Step 8: Disable workflows and update user accounts
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Disabling workflows and updating user accounts"
            $managerCodes = if ($TestingMode) { $config.TestingModeCodes } else { $config.ManagerCodes }
            Disable-BPlusWorkflows -Configuration $config -ManagerCodes $managerCodes -LogFile $logFile

            # Step 9: Update NUUPAUSY text
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Updating NUUPAUSY text"
            $backupDate = (Read-DbaBackupHeader -SqlInstance $config.DatabaseServer -Path $IfasFilePath).BackupFinishDate
            Set-NuupausyText -Configuration $config -BackupDate $backupDate -LogFile $logFile

            # Step 10: Restore dashboards if requested
            if ($RestoreDashboards -and $config.DashboardPath) {
                if ($PSCmdlet.ShouldProcess($config.DashboardPath, 'Restore dashboard files')) {
                    Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Restoring dashboard files"
                    Copy-DashboardFiles -Configuration $config -LogFile $logFile
                }
            }

            # Step 11: Reboot servers
            if ($PSCmdlet.ShouldProcess($config.Servers -join ', ', 'Restart servers')) {
                Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Rebooting environment servers"
                Restart-BPlusServers -Servers $config.Servers -LogFile $logFile
                $result.ServersRebooted = $config.Servers
            }

            # Step 12: Send completion notification
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Sending completion notification"
            Send-CompletionNotification -Configuration $config -Environment $BPEnvironment -LogFile $logFile

            $result.Success = $true
            Write-LogInfo -LogPath $logFile -Message "$(Get-Date -Format 'G') - Database refresh completed successfully"

        } catch {
            $errorMessage = "Database refresh failed: $_"
            $result.Errors += $errorMessage
            Write-LogError -LogPath $logFile -Message $errorMessage
            throw
        }
    }

    end {
        $result.EndTime = Get-Date

        try {
            Stop-Log -LogPath $logFile
        } catch {
            Write-Warning "Failed to stop logging: $_"
        }

        $result
    }
}
