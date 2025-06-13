@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'BPlusDBRestore.psm1'

    # Version number of this module.
    ModuleVersion = '1.3.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = '4d8f7c3e-9b2a-4f5e-8c1d-6a3b9e7f2d1c'

    # Author of this module
    Author = 'Zach Birge'

    # Company or vendor of this module
    CompanyName = 'BusinessPlus Community'

    # Copyright statement for this module
    Copyright = '(c) BusinessPlus Community. All rights reserved. Licensed under GPL-3.0'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for automating BusinessPlus test environment database refreshes. Provides tools to restore databases from production backups, configure security settings, and manage environment-specific configurations for K-12 school districts.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = '4.5'

    # Minimum version of the common language runtime (CLR) required by this module
    # ClrVersion = '4.0'

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{ModuleName = 'PSLogging'; ModuleVersion = '2.2.0'}
        @{ModuleName = 'dbatools'; ModuleVersion = '1.0.0'}
        @{ModuleName = 'PsIni'; ModuleVersion = '3.1.2'}
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Restore-BPlusDatabase'
        'Test-BPlusEnvironment'
        'Get-BPlusConfiguration'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('BusinessPlus', 'Database', 'Restore', 'K12', 'Education', 'ERP', 'Automation', 'SQL')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/businessplus-community/bp-test-env-refresh/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/businessplus-community/bp-test-env-refresh'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'See https://github.com/businessplus-community/bp-test-env-refresh/blob/main/CHANGELOG.md for details.'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/businessplus-community/bp-test-env-refresh/wiki'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}