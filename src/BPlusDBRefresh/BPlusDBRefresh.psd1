@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'BPlusDBRefresh.psm1'

    # Version number of this module.
    ModuleVersion     = '2.1.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author            = 'Zachary V. Birge'

    # Company or vendor of this module
    CompanyName       = 'BusinessPlus Community'

    # Copyright statement for this module
    Copyright         = '(c) 2021-2026 BusinessPlus Community. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'PowerShell module for automating BusinessPlus test environment database refresh operations. Uses JSON configuration for cross-platform compatibility.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'PSLogging',
        'dbatools'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Invoke-BPlusDBRefresh',
        'Get-BPlusConfiguration',
        'Convert-IniToJson'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module for module discovery in online galleries.
            Tags         = @('BusinessPlus', 'Database', 'Refresh', 'Restore', 'SQL')

            # A URL to the license for this module.
            LicenseUri   = ''

            # A URL to the main website for this project.
            ProjectUri   = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.1.0
- Migrated from INI to JSON configuration format for cross-platform compatibility
- Removed PsIni module dependency (uses native ConvertFrom-Json)
- Added Convert-IniToJson utility for migrating existing configurations

## Version 2.0.0
- Complete refactor to PowerShell module structure
- Follow PoshCode PowerShell Practice and Style Guide
- Externalized SQL queries and HTML email templates
- Comprehensive error handling with Try/Catch blocks
- Added Pester tests
- MailKit integration for email notifications (Send-MailMessage deprecated)
'@
        }
    }
}
