BeforeAll {
    
    # NEW: Pre-Specify RegEx Matching Patterns
    $gitTagMatchRegEx   = 'tag:\s?.(\d+(\.\d+)*)' # NOTE - was 'tag:\s*(\d+(?:\.\d+)*)' previously
    $changelogTagMatchRegEx = "^##\s\[(?<Version>(\d+\.){1,3}\d+)\]"    

    # Initialize BuildHelpers if needed
    if (-not $env:BHProjectName) {
        Import-Module BuildHelpers -Force
        Set-BuildEnvironment -Force
    }

    $moduleName         = $env:BHProjectName
    $modulePath         = $env:BHPSModuleManifest
    
    # If running outside of build context, use direct path
    if (-not $modulePath -or -not (Test-Path $modulePath)) {
        $projectRoot = Split-Path -Path $PSScriptRoot -Parent
        $modulePath = Join-Path -Path $projectRoot -ChildPath "$moduleName/$moduleName.psd1"
    }
    
    # Check if we should test the built module or source module
    $outputDir = Join-Path -Path $ENV:BHProjectPath -ChildPath 'Output' -ErrorAction SilentlyContinue
    if ($outputDir -and (Test-Path $outputDir)) {
        $outputModDir = Join-Path -Path $outputDir -ChildPath $moduleName
        if (Test-Path $outputModDir) {
            # Get the latest version directory
            $versionDir = Get-ChildItem -Path $outputModDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            if ($versionDir) {
                $modulePath = Join-Path -Path $versionDir.FullName -ChildPath "$moduleName.psd1"
            }
        }
    }
    
    $manifestData = Test-ModuleManifest -Path $modulePath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue

    $changelogPath    = Join-Path -Path $env:BHProjectPath -Child 'CHANGELOG.md'
    $changelogVersion = Get-Content $changelogPath | ForEach-Object {
        if ($_ -match $changelogTagMatchRegEx) {
            $changelogVersion = $matches.Version
            break
        }
    }

    $script:manifest    = $null
}
Describe 'Module manifest' {

    Context 'Validation' {

        It 'Has a valid manifest' {
            $manifestData | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid name in the manifest' {
            $manifestData.Name | Should -Be $moduleName
        }

        It 'Has a valid root module' {
            $manifestData.RootModule | Should -Be "$($moduleName).psm1"
        }

        It 'Has a valid version in the manifest' {
            $manifestData.Version -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid description' {
            $manifestData.Description | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid author' {
            $manifestData.Author | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid guid' {
            {[guid]::Parse($manifestData.Guid)} | Should -Not -Throw
        }

        It 'Has a valid copyright' {
            $manifestData.CopyRight | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid version in the changelog' {
            $changelogVersion               | Should -Not -BeNullOrEmpty
            $changelogVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'Changelog and manifest versions are the same' {
            $changelogVersion -as [Version] | Should -Be ( $manifestData.Version -as [Version] )
        }
    }
}

Describe 'Git tagging' -Skip {
    BeforeAll {
        $gitTagVersion = $null
        
        # Ensure to only pull in a single git executable (in case multiple git's are found on path).
        if ($git = (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)[0]) {
            $thisCommit = & $git log --decorate --oneline HEAD~1..HEAD
            if ($thisCommit -match $gitTagMatchRegEx) { $gitTagVersion = $matches[1] }
        }
    }

    It 'Is tagged with a valid version' {
        $gitTagVersion               | Should -Not -BeNullOrEmpty
        $gitTagVersion -as [Version] | Should -Not -BeNullOrEmpty
    }

    It 'Matches manifest version' {
        $manifestData.Version -as [Version] | Should -Be ( $gitTagVersion -as [Version])
    }
}