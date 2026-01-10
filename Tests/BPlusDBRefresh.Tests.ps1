#Requires -Modules Pester
<#
.SYNOPSIS
    Main test suite for BPlusDBRefresh module.

.DESCRIPTION
    Validates module structure, manifest, and public function exports.
#>

BeforeAll {
    # Get the module path
    $script:ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\src\BPlusDBRefresh'
    $script:ManifestPath = Join-Path -Path $script:ModulePath -ChildPath 'BPlusDBRefresh.psd1'
}

Describe 'BPlusDBRefresh Module' {
    Context 'Module Structure' {
        It 'Has a valid module manifest' {
            $script:ManifestPath | Should -Exist
            # Test-ModuleManifest validates RequiredModules are installed
            # On systems without PSLogging/dbatools/PsIni, we just verify the file is parseable
            $manifestContent = Get-Content -Path $script:ManifestPath -Raw
            { Invoke-Expression $manifestContent } | Should -Not -Throw
        }

        It 'Has a root module file' {
            $rootModule = Join-Path -Path $script:ModulePath -ChildPath 'BPlusDBRefresh.psm1'
            $rootModule | Should -Exist
        }

        It 'Has a Public folder with functions' {
            $publicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
            $publicPath | Should -Exist
            (Get-ChildItem -Path $publicPath -Filter '*.ps1').Count | Should -BeGreaterThan 0
        }

        It 'Has a Private folder with functions' {
            $privatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'
            $privatePath | Should -Exist
            (Get-ChildItem -Path $privatePath -Filter '*.ps1').Count | Should -BeGreaterThan 0
        }

        It 'Has a Resources folder' {
            $resourcesPath = Join-Path -Path $script:ModulePath -ChildPath 'Resources'
            $resourcesPath | Should -Exist
        }

        It 'Has SQL resources' {
            $sqlPath = Join-Path -Path $script:ModulePath -ChildPath 'Resources\SQL'
            $sqlPath | Should -Exist
            (Get-ChildItem -Path $sqlPath -Filter '*.sql').Count | Should -BeGreaterThan 0
        }

        It 'Has email template resource' {
            $templatePath = Join-Path -Path $script:ModulePath -ChildPath 'Resources\Templates\CompletionEmail.html'
            $templatePath | Should -Exist
        }
    }

    Context 'Module Manifest' {
        BeforeAll {
            # Parse manifest as hashtable to avoid RequiredModules validation
            $script:ManifestData = Invoke-Expression (Get-Content -Path $script:ManifestPath -Raw)
        }

        It 'Has correct module version' {
            $script:ManifestData.ModuleVersion | Should -Be '2.1.0'
        }

        It 'Has correct PowerShell version requirement' {
            $script:ManifestData.PowerShellVersion | Should -Be '5.1'
        }

        It 'Exports Invoke-BPlusDBRefresh function' {
            $script:ManifestData.FunctionsToExport | Should -Contain 'Invoke-BPlusDBRefresh'
        }

        It 'Exports Get-BPlusConfiguration function' {
            $script:ManifestData.FunctionsToExport | Should -Contain 'Get-BPlusConfiguration'
        }

        It 'Has required module dependencies' {
            $requiredModules = $script:ManifestData.RequiredModules
            $requiredModules | Should -Contain 'PSLogging'
            $requiredModules | Should -Contain 'dbatools'
            # PsIni removed - now using native JSON configuration
            $requiredModules | Should -Not -Contain 'PsIni'
        }

        It 'Exports Convert-IniToJson function' {
            $script:ManifestData.FunctionsToExport | Should -Contain 'Convert-IniToJson'
        }

        It 'Has author and company information' {
            $script:ManifestData.Author | Should -Not -BeNullOrEmpty
            $script:ManifestData.CompanyName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function Files' {
        It 'All public function files use approved verbs' {
            $publicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
            $publicFiles = Get-ChildItem -Path $publicPath -Filter '*.ps1'
            $approvedVerbs = (Get-Verb).Verb

            foreach ($file in $publicFiles) {
                $verb = ($file.BaseName -split '-')[0]
                $verb | Should -BeIn $approvedVerbs -Because "$($file.Name) should use an approved verb"
            }
        }

        It 'All private function files use approved verbs' {
            $privatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'
            $privateFiles = Get-ChildItem -Path $privatePath -Filter '*.ps1'
            $approvedVerbs = (Get-Verb).Verb

            foreach ($file in $privateFiles) {
                $verb = ($file.BaseName -split '-')[0]
                $verb | Should -BeIn $approvedVerbs -Because "$($file.Name) should use an approved verb"
            }
        }

        It 'All function files contain CmdletBinding' {
            $publicPath = Join-Path -Path $script:ModulePath -ChildPath 'Public'
            $privatePath = Join-Path -Path $script:ModulePath -ChildPath 'Private'
            $allFiles = @()
            $allFiles += Get-ChildItem -Path $publicPath -Filter '*.ps1'
            $allFiles += Get-ChildItem -Path $privatePath -Filter '*.ps1'

            foreach ($file in $allFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $content | Should -Match '\[CmdletBinding' -Because "$($file.Name) should have CmdletBinding"
            }
        }
    }
}
