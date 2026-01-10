function Restart-BPlusServers {
    <#
    .SYNOPSIS
        Reboots BusinessPlus servers after database refresh.

    .PARAMETER Servers
        Array of server names to reboot.

    .PARAMETER LogFile
        Path to the log file.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Servers,

        [Parameter()]
        [string]$LogFile
    )

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Rebooting servers"
    }

    foreach ($server in $Servers) {
        if ($PSCmdlet.ShouldProcess($server, 'Restart computer')) {
            try {
                if ($LogFile) {
                    Write-LogInfo -LogPath $LogFile -Message "     Rebooting $server"
                }
                Restart-Computer -ComputerName $server -Force -Wait -ErrorAction Stop
            } catch {
                Write-Warning "Failed to reboot $server`: $_"
            }
        }
    }

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
        Write-LogInfo -LogPath $LogFile -Message ' '
    }
}


function Send-CompletionNotification {
    <#
    .SYNOPSIS
        Sends email notification upon completion of database refresh.

    .PARAMETER Configuration
        The configuration object from Get-BPlusConfiguration.

    .PARAMETER Environment
        The environment name that was refreshed.

    .PARAMETER LogFile
        Path to the log file (will be attached).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration,

        [Parameter(Mandatory = $true)]
        [string]$Environment,

        [Parameter()]
        [string]$LogFile
    )

    if ($LogFile) {
        Write-LogInfo -LogPath $LogFile -Message "$(Get-Date -Format 'G') - Sending completion notification"
    }

    try {
        # Verify MailKit is available
        if (-not (Test-MailKitAvailable)) {
            $installResult = Install-MailKitDependency -Force
            if (-not $installResult.Success) {
                throw "MailKit not available: $($installResult.Message)"
            }
        }

        $mailKitInfo = Test-MailKitAvailable -Detailed

        # Load assemblies
        Add-Type -Path $mailKitInfo.MimeKitPath -ErrorAction Stop
        Add-Type -Path $mailKitInfo.MailKitPath -ErrorAction Stop

        # Load HTML template
        $htmlContent = Get-TemplateContent -FileName 'CompletionEmail.html' -Tokens @{
            Environment       = $Environment
            RequestedBy       = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            CompletionMessage = "The Database Refresh of the $Environment Environment has been completed."
            Address           = $Configuration.SmtpSettings.MailMessageAddress
        }

        # Build email
        $smtpClient = New-Object MailKit.Net.Smtp.SmtpClient
        $message = New-Object MimeKit.MimeMessage
        $bodyBuilder = New-Object MimeKit.BodyBuilder

        $message.From.Add($Configuration.SmtpSettings.ReplyToEmail)

        foreach ($recipient in ($Configuration.SmtpSettings.NotificationEmail -split ';')) {
            $message.To.Add($recipient.Trim())
        }

        $message.Subject = "$Environment Database Refresh Complete"

        $bodyBuilder.HtmlBody = $htmlContent
        $bodyBuilder.TextBody = "The Database Refresh of the $Environment Environment has been completed."

        if ($LogFile -and (Test-Path -Path $LogFile)) {
            $null = $bodyBuilder.Attachments.Add($LogFile)
        }

        $message.Body = $bodyBuilder.ToMessageBody()

        # Send email
        $smtpClient.Connect($Configuration.SmtpSettings.Host, $Configuration.SmtpSettings.Port, $false)
        $smtpClient.Send($message)
        $smtpClient.Disconnect($true)
        $smtpClient.Dispose()

        if ($LogFile) {
            Write-LogInfo -LogPath $LogFile -Message 'Completed Successfully.'
        }

    } catch {
        if ($LogFile) {
            Write-LogError -LogPath $LogFile -Message "Failed to send notification: $_"
        }
        Write-Warning "Email notification failed: $_"
    }
}
