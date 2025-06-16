@{
    # Use default rules
    IncludeDefaultRules = $true
    
    # Severity levels to include
    Severity = @(
        'Error',
        'Warning',
        'Information'
    )
    
    # Exclude specific rules
    ExcludeRules = @(
        # We use Write-Host for specific user feedback scenarios
        'PSAvoidUsingWriteHost',
        
        # State-changing functions may not always need ShouldProcess
        'PSUseShouldProcessForStateChangingFunctions',
        
        # These function names are part of the public API and would be breaking changes
        'PSUseSingularNouns',
        
        # ShouldProcess is handled at the main function level
        'PSShouldProcess'
    )
    
    # Rule-specific configurations
    Rules = @{
        # Do not flag 'cd' alias
        PSAvoidUsingCmdletAliases = @{
            Whitelist = @('cd')
        }
        
        # Ensure compatibility with PowerShell Core and Windows PowerShell
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @(
                '5.1',
                '7.0'
            )
        }
        
        # Check if your script uses cmdlets that are compatible
        PSUseCompatibleCmdlets = @{
            Compatibility = @(
                'desktop-5.1.14393.206-windows',
                'core-6.1.0-windows',
                'core-6.1.0-linux',
                'core-6.1.0-macos',
                'core-7.0-windows'
            )
        }
        
        # Check if your script uses commands that are compatible
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework',  # Server 2016
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',   # Server 2019
                'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',  # Windows 10
                'win-8_x64_6.2.9200.0_3.0_x64_4.0.30319.42000_framework',               # Server 2012
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'                                 # Ubuntu
            )
        }
        
        # Check if your script uses types that are compatible across versions
        PSUseCompatibleTypes = @{
            Enable = $true
            TargetProfiles = @(
                'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework',
                'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }

        # Require PascalCase for function names
        PSUseConsistentCasing = @{
            Enable = $true
        }

        # Place open braces on the same line (OTBS style)
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        # Place close braces on a new line
        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
            IgnoreOneLineBlock = $true
            NewLineAfter = $false
        }

        # Use consistent indentation (4 spaces)
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        # Consistent whitespace usage
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }
    }
}