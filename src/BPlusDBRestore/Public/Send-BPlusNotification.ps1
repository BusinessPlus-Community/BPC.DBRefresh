function Send-BPlusNotification {
  <#
  .SYNOPSIS
      Sends email notification upon completion of the restore operation
  
  .DESCRIPTION
      Sends an HTML formatted email to configured recipients with details
      about the completed restore operation.
  
  .PARAMETER Config
      Configuration hashtable containing SMTP settings
  
  .PARAMETER BackupFiles
      Hashtable containing backup file information
  
  .PARAMETER TestingMode
      Whether testing mode was enabled
  
  .PARAMETER StartTime
      When the restore operation started
  
  .PARAMETER EndTime
      When the restore operation completed
  
  .EXAMPLE
      Send-BPlusNotification -Config $config -BackupFiles $files -StartTime $start -EndTime $end
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Config,
    
    [Parameter(Mandatory = $true)]
    [hashtable]$BackupFiles,
    
    [Parameter(Mandatory = $false)]
    [bool]$TestingMode = $false,
    
    [Parameter(Mandatory = $true)]
    [datetime]$StartTime,
    
    [Parameter(Mandatory = $true)]
    [datetime]$EndTime
  )

  Write-BPlusLog -Message "Preparing email notification" -LogPath $script:LogPath
  
  try {
    # Load MailKit assemblies
    $mailKitPath = Join-Path $PSScriptRoot "..\..\..\..\lib\MailKit"
    if (Test-Path $mailKitPath) {
      Add-Type -Path "$mailKitPath\MimeKit.dll"
      Add-Type -Path "$mailKitPath\MailKit.dll"
    }
    else {
      Write-BPlusLog -Message "MailKit assemblies not found, using Send-MailMessage instead" -Level Warning -LogPath $script:LogPath
      
      # Fallback to Send-MailMessage
      $subject = "BusinessPlus Database Restore Completed - $($Config.Environment)"
      $body = Build-EmailHTML -Config $Config -BackupFiles $BackupFiles -TestingMode $TestingMode -StartTime $StartTime -EndTime $EndTime
      
      $mailParams = @{
        To = $Config.SMTPTo -split ';'
        From = $Config.SMTPFrom
        Subject = $subject
        Body = $body
        BodyAsHtml = $true
        SmtpServer = $Config.SMTPServer
        Port = $Config.SMTPPort
      }
      
      if ($Config.SMTPUseSSL) {
        $mailParams.UseSSL = $true
      }
      
      Send-MailMessage @mailParams
      Write-BPlusLog -Message "Email notification sent successfully" -LogPath $script:LogPath
      return
    }
    
    # Create message using MailKit
    $message = New-Object MimeKit.MimeMessage
    $message.From.Add([MimeKit.InternetAddress]::Parse($Config.SMTPFrom))
    
    foreach ($recipient in ($Config.SMTPTo -split ';')) {
      $message.To.Add([MimeKit.InternetAddress]::Parse($recipient.Trim()))
    }
    
    $message.Subject = "BusinessPlus Database Restore Completed - $($Config.Environment)"
    
    # Build HTML body
    $htmlBody = Build-EmailHTML -Config $Config -BackupFiles $BackupFiles -TestingMode $TestingMode -StartTime $StartTime -EndTime $EndTime
    
    $bodyBuilder = New-Object MimeKit.BodyBuilder
    $bodyBuilder.HtmlBody = $htmlBody
    $message.Body = $bodyBuilder.ToMessageBody()
    
    # Send message
    $client = New-Object MailKit.Net.Smtp.SmtpClient
    $client.Connect($Config.SMTPServer, $Config.SMTPPort, $Config.SMTPUseSSL)
    $client.Send($message)
    $client.Disconnect($true)
    
    Write-BPlusLog -Message "Email notification sent successfully via MailKit" -LogPath $script:LogPath
  }
  catch {
    Write-BPlusLog -Message "Error sending email notification: $_" -Level Error -LogPath $script:LogPath
    throw
  }
}