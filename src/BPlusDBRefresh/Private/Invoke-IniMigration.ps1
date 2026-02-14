function Invoke-IniMigration {
    <#
    .SYNOPSIS
        Migrates an INI configuration file to JSON format.

    .DESCRIPTION
        Handles the migration of legacy INI configuration files to the new JSON format.
        Creates a backup of the original file, converts to JSON, and renames the original
        to .ini.bak. Optionally prompts the user for confirmation before migration.

    .PARAMETER IniPath
        The path to the INI configuration file to migrate.

    .PARAMETER SkipPrompt
        If specified, skips the interactive confirmation prompt and proceeds with migration.
        Useful for automation and CI/CD scenarios.

    .EXAMPLE
        Invoke-IniMigration -IniPath 'C:\Scripts\config.ini'
        Prompts user for confirmation, then migrates the INI file to JSON.

    .EXAMPLE
        Invoke-IniMigration -IniPath 'C:\Scripts\config.ini' -SkipPrompt
        Migrates the INI file to JSON without prompting.

    .OUTPUTS
        String containing the path to the newly created JSON configuration file.

    .NOTES
        The original INI file is preserved as .ini.bak for manual rollback if needed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$IniPath,

        [Parameter()]
        [switch]$SkipPrompt
    )

    begin {
        Write-Verbose "Starting INI to JSON migration for: $IniPath"
    }

    process {
        try {
            # Resolve full path
            $IniPath = Resolve-Path -Path $IniPath | Select-Object -ExpandProperty Path

            # Calculate output paths
            $jsonPath = $IniPath -replace '\.ini$', '.json'
            $backupPath = "$IniPath.bak"

            # Prompt user unless SkipPrompt is set
            if (-not $SkipPrompt) {
                $title = "Configuration Migration Required"
                $message = @"
The configuration file uses the legacy INI format:
  $IniPath

BPlusDBRefresh now uses JSON configuration for cross-platform compatibility.
A backup will be created at: $backupPath
New JSON config will be created at: $jsonPath

Do you want to migrate to JSON format?
"@

                $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Migrate configuration to JSON format"
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancel and exit"
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

                $result = $Host.UI.PromptForChoice($title, $message, $options, 0)

                if ($result -eq 1) {
                    throw [System.OperationCanceledException]::new(
                        "Migration cancelled by user. Please convert your INI configuration to JSON format manually using Convert-IniToJson, or allow automatic migration."
                    )
                }
            }

            Write-Verbose "Creating backup at: $backupPath"

            # Step 1: Create backup by copying the INI file
            Copy-Item -Path $IniPath -Destination $backupPath -Force -ErrorAction Stop

            Write-Verbose "Converting INI to JSON..."

            # Step 2: Convert INI to JSON using existing function
            # Dot-source Convert-IniToJson if not already available
            $convertFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Public\Convert-IniToJson.ps1'
            if (-not (Get-Command -Name Convert-IniToJson -ErrorAction SilentlyContinue)) {
                . $convertFunctionPath
            }

            # Perform conversion
            $conversionResult = Convert-IniToJson -IniPath $IniPath -OutputPath $jsonPath -ErrorAction Stop

            # Step 3: Verify JSON was created successfully
            if (-not (Test-Path -Path $jsonPath)) {
                throw "JSON conversion failed: Output file was not created at $jsonPath"
            }

            # Verify JSON is valid
            $null = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json -ErrorAction Stop

            Write-Verbose "JSON file created successfully at: $jsonPath"

            # Step 4: Rename original INI to .bak (this effectively moves it)
            # The copy we made earlier becomes the backup, now remove the original
            Remove-Item -Path $IniPath -Force -ErrorAction Stop

            Write-Verbose "Original INI file renamed to backup: $backupPath"
            Write-Verbose "Migration complete!"

            # Return path to new JSON file
            return $jsonPath

        } catch [System.OperationCanceledException] {
            # Re-throw cancellation exceptions as-is
            throw
        } catch {
            $errorMessage = "INI to JSON migration failed: $($_.Exception.Message)"
            throw [System.InvalidOperationException]::new($errorMessage, $_.Exception)
        }
    }
}
