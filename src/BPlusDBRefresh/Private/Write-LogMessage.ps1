function Write-LogMessage {
    <#
    .SYNOPSIS
        Writes a message to the log file with consistent formatting.

    .DESCRIPTION
        Wrapper function for PSLogging module functions that provides consistent
        formatting and timestamp handling. Supports Info, Warning, and Error levels.

    .PARAMETER Message
        The message to write to the log.

    .PARAMETER LogFile
        The path to the log file.

    .PARAMETER Level
        The log level: Info, Warning, or Error. Default is Info.

    .PARAMETER ExitOnError
        When specified with Error level, exits gracefully after logging.

    .EXAMPLE
        Write-LogMessage -Message 'Starting operation' -LogFile $logFile

    .EXAMPLE
        Write-LogMessage -Message 'Something went wrong' -LogFile $logFile -Level Error

    .OUTPUTS
        None.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info',

        [Parameter()]
        [switch]$ExitOnError
    )

    # Format message with timestamp if not empty
    $formattedMessage = if ($Message) {
        "$(Get-Date -Format 'G') - $Message"
    } else {
        ' '
    }

    try {
        switch ($Level) {
            'Info' {
                Write-LogInfo -LogPath $LogFile -Message $formattedMessage
            }
            'Warning' {
                Write-LogWarning -LogPath $LogFile -Message $formattedMessage
            }
            'Error' {
                if ($ExitOnError) {
                    Write-LogError -LogPath $LogFile -Message $formattedMessage -ExitGracefully
                } else {
                    Write-LogError -LogPath $LogFile -Message $formattedMessage
                }
            }
        }
    } catch {
        # Fallback to console output if logging fails
        switch ($Level) {
            'Info' { Write-Verbose $formattedMessage }
            'Warning' { Write-Warning $formattedMessage }
            'Error' { Write-Error $formattedMessage }
        }
    }
}


function Write-LogSeparator {
    <#
    .SYNOPSIS
        Writes a separator line to the log for visual separation.

    .DESCRIPTION
        Writes an empty line or separator to the log file for improved readability.

    .PARAMETER LogFile
        The path to the log file.

    .EXAMPLE
        Write-LogSeparator -LogFile $logFile
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile
    )

    try {
        Write-LogInfo -LogPath $LogFile -Message ' '
    } catch {
        # Silently ignore separator write failures
    }
}
