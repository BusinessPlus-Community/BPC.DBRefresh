function Show-ConfigurationReview {
    <#
    .SYNOPSIS
        Displays the configuration summary for user review before database refresh.

    .DESCRIPTION
        Formats and displays all configuration settings that will be used during
        the database refresh operation, allowing the user to verify before proceeding.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER IfasFilePath
        Path to the IFAS backup file.

    .PARAMETER SyscatFilePath
        Path to the Syscat backup file.

    .PARAMETER AspnetFilePath
        Optional path to the ASP.NET backup file.

    .PARAMETER TestingMode
        Whether testing mode is enabled.

    .PARAMETER RestoreDashboards
        Whether dashboard restoration is enabled.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [string]$IfasFilePath,

        [Parameter(Mandatory = $true)]
        [string]$SyscatFilePath,

        [Parameter()]
        [string]$AspnetFilePath,

        [Parameter()]
        [switch]$TestingMode,

        [Parameter()]
        [switch]$RestoreDashboards
    )

    $divider = '-' * 80

    Write-Host "`n$divider" -ForegroundColor Cyan
    Write-Host "  DATABASE REFRESH CONFIGURATION REVIEW" -ForegroundColor Cyan
    Write-Host "  Environment: $($Configuration.Environment)" -ForegroundColor Yellow
    Write-Host "$divider`n" -ForegroundColor Cyan

    # Database Server Section
    Write-Host "DATABASE SERVER" -ForegroundColor Green
    Write-Host "  Server:            $($Configuration.DatabaseServer)"
    Write-Host "  Data Path:         $($Configuration.FilePaths.Data)"
    Write-Host "  Log Path:          $($Configuration.FilePaths.Log)"
    Write-Host "  Images Path:       $($Configuration.FilePaths.Images)"
    Write-Host ""

    # Security Accounts Section
    Write-Host "SECURITY ACCOUNTS" -ForegroundColor Green
    Write-Host "  IUSR Source:       $($Configuration.Security.IusrSource)"
    Write-Host "  IUSR Destination:  $($Configuration.Security.IusrDestination)"
    Write-Host "  Admin Source:      $($Configuration.Security.AdminSource)"
    Write-Host "  Admin Destination: $($Configuration.Security.AdminDestination)"
    Write-Host ""

    # Databases Section
    Write-Host "$divider" -ForegroundColor DarkGray
    Write-Host "DATABASES TO RESTORE" -ForegroundColor Green

    Write-Host "  IFAS Database:     $($Configuration.IfasDatabase)"
    Write-Host "    Backup File:     $IfasFilePath"

    Write-Host "  Syscat Database:   $($Configuration.SyscatDatabase)"
    Write-Host "    Backup File:     $SyscatFilePath"

    if ($Configuration.AspnetDatabase -and $AspnetFilePath) {
        Write-Host "  ASP.NET Database:  $($Configuration.AspnetDatabase)"
        Write-Host "    Backup File:     $AspnetFilePath"
    }
    Write-Host ""

    # BusinessPlus Servers Section
    Write-Host "$divider" -ForegroundColor DarkGray
    Write-Host "BUSINESSPLUS SERVERS" -ForegroundColor Green
    foreach ($server in $Configuration.Servers) {
        Write-Host "  - $server"
    }
    Write-Host "  IPC Daemon:        $($Configuration.IpcDaemon)"
    Write-Host ""

    # User Account Settings
    Write-Host "USER ACCOUNT SETTINGS" -ForegroundColor Green
    Write-Host "  NUUPAUSY Text:     $($Configuration.NuupausyText)"
    Write-Host "  Dummy Email:       $($Configuration.DummyEmail)"
    Write-Host "  Dashboard URL:     $($Configuration.DashboardUrl)"

    $managerCodesDisplay = if ($TestingMode) {
        "Testing Mode - $($Configuration.TestingModeCodes -join ', ')"
    } else {
        $Configuration.ManagerCodes -join ', '
    }
    Write-Host "  Manager Codes:     $managerCodesDisplay"
    Write-Host ""

    # Options
    if ($RestoreDashboards -and $Configuration.DashboardPath) {
        Write-Host "DASHBOARD RESTORATION" -ForegroundColor Green
        $dashParts = $Configuration.DashboardPath -split ':'
        if ($dashParts.Count -ge 2) {
            Write-Host "  Source:            $($dashParts[0])"
            Write-Host "  Destination:       $($dashParts[1])"
        }
        Write-Host ""
    }

    # SMTP Settings
    Write-Host "$divider" -ForegroundColor DarkGray
    Write-Host "NOTIFICATION SETTINGS" -ForegroundColor Green
    Write-Host "  SMTP Host:         $($Configuration.SmtpSettings.Host)"
    Write-Host "  SMTP Port:         $($Configuration.SmtpSettings.Port)"
    Write-Host "  Reply-To:          $($Configuration.SmtpSettings.ReplyToEmail)"
    Write-Host "  Notify:            $($Configuration.SmtpSettings.NotificationEmail)"
    Write-Host ""

    Write-Host $divider -ForegroundColor Cyan
}


function Request-UserConfirmation {
    <#
    .SYNOPSIS
        Prompts the user to confirm the database refresh operation.

    .DESCRIPTION
        Displays a confirmation prompt and returns the user's choice.
        Returns $true to proceed or $false to cancel.

    .PARAMETER Environment
        The environment name being refreshed.

    .OUTPUTS
        System.Boolean - $true to proceed, $false to cancel.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Environment
    )

    $title = 'Database Refresh Confirmation'
    $question = "Do you want to proceed with the database refresh of $Environment`?"

    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Proceed with database refresh'),
        [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Cancel and exit')
    )

    # Default to No (index 1) for safety
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)

    return ($decision -eq 0)
}
