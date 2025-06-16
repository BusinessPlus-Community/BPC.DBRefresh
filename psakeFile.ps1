properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $false
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Test.OutputFile = 'out/testResults.xml'
    
    # Use project-specific PSScriptAnalyzer settings
    $PSBPreference.Test.ScriptAnalysis.SettingsPath = './tests/PSScriptAnalyzerSettings.psd1'
}

task default -depends Test

task Test -FromModule PowerShellBuild -Version '0.6.1'