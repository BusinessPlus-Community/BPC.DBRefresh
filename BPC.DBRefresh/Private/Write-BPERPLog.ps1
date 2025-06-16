function Write-BPERPLog {
    <#
  .SYNOPSIS
      Writes a log entry to the BusinessPlus restore log file

  .DESCRIPTION
      Wrapper function for consistent logging throughout the module.
      Uses the PSLogging module for structured logging.

  .PARAMETER Message
      The message to log

  .PARAMETER Level
      The log level (Info, Warning, Error)

  .PARAMETER LogPath
      Path to the log file

  .EXAMPLE
      Write-BPERPLog -Message "Starting database restore" -Level Info -LogPath $logFile
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    switch ($Level) {
        'Info' {
            Write-LogInfo -LogPath $LogPath -Message $Message
            Write-Verbose $Message
        }
        'Warning' {
            Write-LogWarning -LogPath $LogPath -Message $Message
            Write-Warning $Message
        }
        'Error' {
            Write-LogError -LogPath $LogPath -Message $Message
            Write-Error $Message
        }
    }
}

