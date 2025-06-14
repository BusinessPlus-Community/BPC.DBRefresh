@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    
    # Module dependencies (Required for the module to function)
    'PSLogging' = @{
        Version = '2.2.0'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'dbatools' = @{
        Version = '1.0.0'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'PsIni' = @{
        Version = '3.1.2'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    
    # Build and Development dependencies
    'Pester' = @{
        Version = '5.0.0'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'PSScriptAnalyzer' = @{
        Version = '1.19.1'
    }
    'psake' = @{
        Version = '4.9.0'
    }
    'BuildHelpers' = @{
        Version = '2.0.16'
    }
    'PowerShellBuild' = @{
        Version = '0.6.1'
    }
}