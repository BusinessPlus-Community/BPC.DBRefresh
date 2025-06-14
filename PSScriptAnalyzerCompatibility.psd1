@{
  # This file is used for compatibility checking on Windows CI
  # It includes only the compatibility rules that can fail on non-Windows platforms
  
  IncludeRules = @(
    'PSUseCompatibleCommands',
    'PSUseCompatibleTypes',
    'PSUseCompatibleCmdlets',
    'PSUseCompatibleSyntax'
  )
  
  Rules = @{
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
  }
}