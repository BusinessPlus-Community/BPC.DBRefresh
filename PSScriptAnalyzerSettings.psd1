@{
  # Use Severity when you want to limit the generated diagnostic records to a
  # subset of: Error, Warning and Information.
  # Uncomment the following line if you only want Errors and Warnings but
  # not Information diagnostic records.
  #Severity = @('Error','Warning')

  # Use IncludeRules when you want to run only a subset of the default rule set.
  #IncludeRules = @('PSAvoidDefaultValueSwitchParameter',
  #                 'PSMissingModuleManifestField',
  #                 'PSReservedCmdletChar',
  #                 'PSReservedParams',
  #                 'PSShouldProcess',
  #                 'PSUseApprovedVerbs',
  #                 'PSUseDeclaredVarsMoreThanAssignments')

  # Use ExcludeRules when you want to run most of the default set of rules except
  # for a few rules you wish to "exclude".  Note: if a rule is in both IncludeRules
  # and ExcludeRules, the rule will be excluded.
  ExcludeRules = @(
    # We use Write-Host for specific user feedback scenarios
    'PSAvoidUsingWriteHost',
    
    # We need positional parameters for backward compatibility
    'PSAvoidUsingPositionalParameters',
    
    # Some aliases are used for clarity in specific contexts
    'PSAvoidUsingCmdletAliases',
    
    # Disable alignment rules that are causing issues
    'PSAlignAssignmentStatement',
    'PSAvoidTrailingWhitespace'
  )

  # You can use the following entry to supply parameters to rules that take parameters.
  # For instance, the PSAvoidUsingCmdletAliases rule takes a whitelist for aliases you
  # want to allow.
  Rules = @{
    # Do not flag 'cd' alias.
    PSAvoidUsingCmdletAliases = @{
      # Whitelist = @('cd', 'cp')
    }

    # Check if your script uses cmdlets that are compatible with PowerShell Core,
    # version 6.0.0-alpha, on Linux.
    PSUseCompatibleCmdlets = @{
      Compatibility = @(
        'desktop-5.1.14393.206-windows',
        'core-6.1.0-windows',
        'core-6.1.0-linux',
        'core-6.1.0-macos'
      )
    }

    # Check if your script uses commands that are compatible with PowerShell Core,
    # version 6.1.0, on Linux, Windows and macOS.
    PSUseCompatibleCommands = @{
      Enable = $true
      TargetProfiles = @(
        'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework',
        'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework',
        'win-8_x64_6.2.9200.0_3.0_x64_4.0.30319.42000_framework'
      )
    }

    # Check if your script uses types that are compatible with PowerShell Core
    PSUseCompatibleTypes = @{
      Enable = $true
      TargetProfiles = @(
        'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework',
        'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework'
      )
    }

    # Require PascalCase for function names
    PSUseConsistentCasing = @{
      Enable = $true
    }

    # Require backticks for continuation
    PSAlignAssignmentStatement = @{
      Enable = $true
      CheckHashtable = $true
    }

    # Place open braces on the same line
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

    # Use consistent indentation
    PSUseConsistentIndentation = @{
      Enable = $true
      IndentationSize = 2
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