function Convert-IniToJson {
    <#
    .SYNOPSIS
        Converts an INI configuration file to JSON format.

    .DESCRIPTION
        Parses an existing INI configuration file and converts it to the new JSON format
        used by BPlusDBRefresh. This utility helps migrate from the old PsIni-based
        configuration to the new cross-platform JSON format.

    .PARAMETER IniPath
        The path to the INI configuration file to convert.

    .PARAMETER OutputPath
        Optional path to write the JSON output. If not specified, outputs to console.

    .PARAMETER Environments
        Array of environment names to extract from the INI file. If not specified,
        attempts to auto-detect environments from the sqlServer section.

    .EXAMPLE
        Convert-IniToJson -IniPath 'C:\Scripts\bpcBPlusDBRefresh.ini'
        Outputs the converted JSON to the console.

    .EXAMPLE
        Convert-IniToJson -IniPath 'C:\Scripts\bpcBPlusDBRefresh.ini' -OutputPath 'C:\Scripts\bpcBPlusDBRefresh.json'
        Writes the converted JSON to a file.

    .EXAMPLE
        Convert-IniToJson -IniPath 'config.ini' -Environments @('TEST1', 'TEST2')
        Converts only the specified environments.

    .OUTPUTS
        String containing the JSON configuration, or writes to file if OutputPath specified.

    .NOTES
        The conversion maps INI sections to JSON structure as follows:
        - Environment-specific settings (sqlServer, database, etc.) go under environments.<ENV>
        - SMTP settings go under smtp (shared across all environments)
        - Comma-separated values are converted to JSON arrays
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IniPath,

        [Parameter(Position = 1)]
        [string]$OutputPath,

        [Parameter()]
        [string[]]$Environments
    )

    begin {
        Write-Verbose "Reading INI file: $IniPath"
    }

    process {
        try {
            # Read and parse INI file
            $iniContent = @{}
            $currentSection = $null

            foreach ($line in Get-Content -Path $IniPath) {
                $line = $line.Trim()

                # Skip empty lines and comments
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#') -or $line.StartsWith(';')) {
                    continue
                }

                # Section header
                if ($line -match '^\[(.+)\]$') {
                    $currentSection = $Matches[1]
                    if (-not $iniContent.ContainsKey($currentSection)) {
                        $iniContent[$currentSection] = @{}
                    }
                    continue
                }

                # Key-value pair
                if ($currentSection -and $line -match '^([^=]+)=(.*)$') {
                    $key = $Matches[1].Trim()
                    $value = $Matches[2].Trim()
                    $iniContent[$currentSection][$key] = $value
                }
            }

            # Auto-detect environments if not specified
            if (-not $Environments -and $iniContent.ContainsKey('sqlServer')) {
                $Environments = $iniContent['sqlServer'].Keys | Where-Object { $_ -ne '_comment' }
                Write-Verbose "Auto-detected environments: $($Environments -join ', ')"
            }

            if (-not $Environments) {
                throw "No environments found in INI file. Specify -Environments parameter."
            }

            # Helper to get value from section
            $getValue = {
                param([string]$Section, [string]$Key)
                if ($iniContent.ContainsKey($Section) -and $iniContent[$Section].ContainsKey($Key)) {
                    return $iniContent[$Section][$Key]
                }
                return $null
            }

            # Helper to convert comma-separated to array
            $toArray = {
                param([string]$Value)
                if ([string]::IsNullOrWhiteSpace($Value)) {
                    return @()
                }
                return @($Value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }

            # Build JSON structure
            $jsonObject = @{
                '$schema' = './bpcBPlusDBRefresh.schema.json'
                environments = @{}
                smtp = @{}
            }

            # Convert SMTP settings (shared)
            $smtpSection = $iniContent['SMTP']
            if ($smtpSection) {
                $jsonObject.smtp = @{
                    host = & $getValue 'SMTP' 'host'
                    port = if ($smtpSection['port']) { [int]$smtpSection['port'] } else { 25 }
                    ssl = if ($smtpSection['ssl'] -eq 'Y') { $true } else { $false }
                    username = & $getValue 'SMTP' 'username'
                    password = & $getValue 'SMTP' 'password'
                    replyToEmail = & $getValue 'SMTP' 'replyToEmail'
                    notificationEmail = & $getValue 'SMTP' 'notificationEmail'
                    mailMessageAddress = & $getValue 'SMTP' 'mailMessageAddress'
                }
            }

            # Convert each environment
            foreach ($env in $Environments) {
                Write-Verbose "Converting environment: $env"

                $envConfig = @{
                    sqlServer = & $getValue 'sqlServer' $env
                    database = & $getValue 'database' $env
                    syscat = & $getValue 'syscat' $env
                    aspnet = & $getValue 'aspnet' $env
                    filepathData = & $getValue 'filepathData' $env
                    filepathLog = & $getValue 'filepathLog' $env
                    filepathImages = & $getValue 'filepathImages' $env
                    fileDriveData = & $toArray (& $getValue 'fileDriveData' $env)
                    fileDriveSyscat = & $toArray (& $getValue 'fileDriveSyscat' $env)
                    fileDriveAspnet = & $toArray (& $getValue 'fileDriveAspnet' $env)
                    environmentServers = & $toArray (& $getValue 'environmentServers' $env)
                    ipcDaemon = & $getValue 'ipc_daemon' $env
                    nuupausy = & $getValue 'NUUPAUSY' $env
                    iusrSource = & $getValue 'IUSRSource' $env
                    iusrDestination = & $getValue 'IUSRDestination' $env
                    adminSource = & $getValue 'AdminSource' $env
                    adminDestination = & $getValue 'AdminDestination' $env
                    dboSource = & $getValue 'dboSource' $env
                    dboDestination = & $getValue 'dboDestination' $env
                    dummyEmail = & $getValue 'DummyEmail' $env
                    managerCodes = & $toArray (& $getValue 'ManagerCode' $env)
                    testingModeCodes = & $toArray (& $getValue 'TestingMode' $env)
                    dashboardUrl = & $getValue 'dashboardURL' $env
                    dashboardFiles = & $getValue 'dashboardFiles' $env
                }

                # Remove null values for cleaner output
                $cleanConfig = @{}
                foreach ($key in $envConfig.Keys) {
                    $value = $envConfig[$key]
                    if ($null -ne $value -and $value -ne '' -and @($value).Count -gt 0) {
                        $cleanConfig[$key] = $value
                    }
                }

                $jsonObject.environments[$env] = $cleanConfig
            }

            # Convert to JSON with proper formatting
            $jsonOutput = $jsonObject | ConvertTo-Json -Depth 10

            if ($OutputPath) {
                $jsonOutput | Out-File -FilePath $OutputPath -Encoding utf8
                Write-Verbose "JSON configuration written to: $OutputPath"
                return "Configuration converted and saved to: $OutputPath"
            } else {
                return $jsonOutput
            }

        } catch {
            $errorMessage = "Failed to convert INI to JSON: $($_.Exception.Message)"
            throw [System.InvalidOperationException]::new($errorMessage, $_.Exception)
        }
    }
}
