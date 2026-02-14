function Get-BPlusConfiguration {
    <#
    .SYNOPSIS
        Parses and validates the BusinessPlus environment configuration file.

    .DESCRIPTION
        Reads the JSON configuration file and extracts settings for the specified
        BusinessPlus environment. Returns a structured object with all configuration
        values needed for database refresh operations.

        If an INI file is provided, automatically offers to migrate it to JSON format.

    .PARAMETER Path
        The path to the configuration file (JSON or INI). If an INI file is provided,
        the user will be prompted to migrate to JSON format.

    .PARAMETER Environment
        The name of the BusinessPlus environment to load configuration for (e.g., TEST1).

    .PARAMETER SkipMigrationPrompt
        If specified, skips the interactive migration prompt when an INI file is detected
        and proceeds with automatic migration. Useful for automation and CI/CD scenarios.

    .EXAMPLE
        $config = Get-BPlusConfiguration -Path 'C:\Scripts\bpcBPlusDBRefresh.json' -Environment 'TEST1'

    .EXAMPLE
        $config = Get-BPlusConfiguration -Path $configPath -Environment 'TEST2'
        $config.DatabaseServer
        $config.Servers

    .EXAMPLE
        $config = Get-BPlusConfiguration -Path 'C:\Scripts\config.ini' -Environment 'TEST1'
        # Prompts user to migrate INI to JSON, then loads configuration

    .EXAMPLE
        $config = Get-BPlusConfiguration -Path 'config.ini' -Environment 'TEST1' -SkipMigrationPrompt
        # Automatically migrates INI to JSON without prompting

    .OUTPUTS
        PSCustomObject containing all configuration values for the specified environment.

    .NOTES
        Uses native PowerShell ConvertFrom-Json for cross-platform compatibility.
        Legacy INI files are automatically migrated to JSON with user confirmation.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Environment,

        [Parameter()]
        [switch]$SkipMigrationPrompt
    )

    begin {
        Write-Verbose "Loading configuration from $Path for environment $Environment"
    }

    process {
        try {
            # Check if file is INI format (by extension)
            if ($Path -match '\.ini$') {
                Write-Verbose "INI file detected, initiating migration..."

                # Dot-source the migration function
                $migrationFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Private\Invoke-IniMigration.ps1'
                . $migrationFunctionPath

                # Perform migration (will prompt unless SkipMigrationPrompt is set)
                $Path = Invoke-IniMigration -IniPath $Path -SkipPrompt:$SkipMigrationPrompt

                Write-Verbose "Migration complete, loading JSON from: $Path"
            }

            # Parse JSON file
            $jsonContent = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

            # Validate environment exists
            if (-not $jsonContent.environments.PSObject.Properties[$Environment]) {
                throw "Environment '$Environment' not found in configuration file"
            }

            $envConfig = $jsonContent.environments.$Environment

            # Helper function to get value with validation
            $getValue = {
                param([string]$Key, [bool]$Required = $false, [object]$Source = $envConfig)

                $value = $Source.$Key

                if ($Required -and ($null -eq $value -or ([string]$value).Trim() -eq '')) {
                    throw "Required configuration value missing: $Key"
                }

                $value
            }

            # Helper function to get array values (handles both native arrays and comma-separated strings)
            $getList = {
                param([string]$Key, [bool]$Required = $false, [object]$Source = $envConfig)

                $value = & $getValue $Key $Required $Source

                if ($null -eq $value) {
                    return @()
                }

                # If already an array, return it
                if ($value -is [array]) {
                    return $value
                }

                # If string, split by comma
                if ($value -is [string]) {
                    if ([string]::IsNullOrWhiteSpace($value)) {
                        return @()
                    }
                    return $value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                }

                return @($value)
            }

            # Get SMTP settings (shared across environments)
            $smtpConfig = $jsonContent.smtp

            # Build configuration object
            $config = [PSCustomObject]@{
                # Environment info
                Environment       = $Environment

                # Database server
                DatabaseServer    = & $getValue 'sqlServer' $true

                # Database names
                IfasDatabase      = & $getValue 'database' $true
                SyscatDatabase    = & $getValue 'syscat' $true
                AspnetDatabase    = & $getValue 'aspnet' $false

                # File paths on SQL Server
                FilePaths         = [PSCustomObject]@{
                    Data   = & $getValue 'filepathData' $true
                    Log    = & $getValue 'filepathLog' $true
                    Images = & $getValue 'filepathImages' $false
                }

                # Database file drive mappings (for restore)
                FileDrives        = [PSCustomObject]@{
                    Ifas   = & $getList 'fileDriveData' $true
                    Syscat = & $getList 'fileDriveSyscat' $true
                    Aspnet = & $getList 'fileDriveAspnet' $false
                }

                # BusinessPlus servers
                Servers           = & $getList 'environmentServers' $true

                # IPC Daemon service name
                IpcDaemon         = & $getValue 'ipcDaemon' $true

                # SMTP settings
                SmtpSettings      = [PSCustomObject]@{
                    Host              = & $getValue 'host' $true $smtpConfig
                    Port              = if ($smtpConfig.port) { [int]$smtpConfig.port } else { 25 }
                    ReplyToEmail      = & $getValue 'replyToEmail' $true $smtpConfig
                    NotificationEmail = & $getValue 'notificationEmail' $true $smtpConfig
                    MailMessageAddress = & $getValue 'mailMessageAddress' $false $smtpConfig
                }

                # Security account mappings
                Security          = [PSCustomObject]@{
                    IusrSource        = & $getValue 'iusrSource' $true
                    IusrDestination   = & $getValue 'iusrDestination' $true
                    AdminSource       = & $getValue 'adminSource' $true
                    AdminDestination  = & $getValue 'adminDestination' $true
                    DboSource         = & $getValue 'dboSource' $false
                    DboDestination    = & $getValue 'dboDestination' $false
                }

                # User account settings
                DummyEmail        = & $getValue 'dummyEmail' $true
                ManagerCodes      = & $getList 'managerCodes' $true
                TestingModeCodes  = & $getList 'testingModeCodes' $false

                # Display text
                NuupausyText      = & $getValue 'nuupausy' $true

                # Dashboard settings
                DashboardUrl      = & $getValue 'dashboardUrl' $false
                DashboardPath     = & $getValue 'dashboardFiles' $false

                # Connection strings (computed)
                ConnectionStrings = $null
            }

            # Use AdminSource/Destination for DBO if not explicitly set
            if ([string]::IsNullOrWhiteSpace($config.Security.DboSource)) {
                $config.Security.DboSource = $config.Security.AdminSource
            }
            if ([string]::IsNullOrWhiteSpace($config.Security.DboDestination)) {
                $config.Security.DboDestination = $config.Security.AdminDestination
            }

            # Build connection strings
            $config.ConnectionStrings = [PSCustomObject]@{
                Ifas   = "Data Source=$($config.DatabaseServer); Database=$($config.IfasDatabase); Trusted_Connection=True;"
                Syscat = "Data Source=$($config.DatabaseServer); Database=$($config.SyscatDatabase); Trusted_Connection=True;"
                Aspnet = if ($config.AspnetDatabase) {
                    "Data Source=$($config.DatabaseServer); Database=$($config.AspnetDatabase); Trusted_Connection=True;"
                } else { $null }
            }

            Write-Verbose "Configuration loaded successfully for environment $Environment"
            $config

        } catch {
            $errorMessage = "Failed to load configuration: $($_.Exception.Message)"
            throw [System.Configuration.ConfigurationException]::new($errorMessage, $_.Exception)
        }
    }
}
