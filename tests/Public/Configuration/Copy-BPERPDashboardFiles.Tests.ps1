BeforeAll {
    $moduleRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    $modulePath = Join-Path -Path $moduleRoot -ChildPath 'BPC.DBRefresh'
    
    # Remove any existing module instances first
    Get-Module -Name BPC.DBRefresh | Remove-Module -Force
    
    # Import the module
    Import-Module $modulePath -Force
    
    # Set up module-level variables for testing
    $module = Get-Module BPC.DBRefresh
    & $module {
        $script:LogPath = Join-Path $TestDrive 'test.log'
    }
}

Describe 'Copy-BPERPDashboardFiles' {
    Context 'Function exists' {
        It 'Should have the Copy-BPERPDashboardFiles function' {
            Get-Command -Name Copy-BPERPDashboardFiles -Module BPC.DBRefresh | Should -Not -BeNullOrEmpty
        }

        It 'Should have the correct parameters' {
            $command = Get-Command -Name Copy-BPERPDashboardFiles -Module BPC.DBRefresh
            $command.Parameters.Keys | Should -Contain 'Config'
        }

        It 'Should have mandatory parameters marked correctly' {
            $command = Get-Command -Name Copy-BPERPDashboardFiles -Module BPC.DBRefresh
            $command.Parameters['Config'].Attributes.Mandatory | Should -Contain $true
        }
    }

    Context 'Parameter validation' {
        It 'Should accept Hashtable type for Config parameter' {
            $command = Get-Command -Name Copy-BPERPDashboardFiles -Module BPC.DBRefresh
            $command.Parameters['Config'].ParameterType.Name | Should -Be 'Hashtable'
        }
    }

    Context 'Function behavior' -Tag 'Integration' {
        BeforeEach {
            # Create test directories
            $testRoot = Join-Path -Path $TestDrive -ChildPath 'DashboardTest'
            $sourcePath = Join-Path -Path $testRoot -ChildPath 'Source'
            $destPath = Join-Path -Path $testRoot -ChildPath 'Destination'
            
            New-Item -Path $sourcePath -ItemType Directory -Force | Out-Null
            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
            
            # Create test files
            '{"test": "dashboard1"}' | Out-File -FilePath (Join-Path -Path $sourcePath -ChildPath 'dashboard1.json')
            '{"test": "dashboard2"}' | Out-File -FilePath (Join-Path -Path $sourcePath -ChildPath 'dashboard2.json')
            'Not a dashboard' | Out-File -FilePath (Join-Path -Path $sourcePath -ChildPath 'readme.txt')
            
            # Set up module-level variables for each test
            & (Get-Module BPC.DBRefresh) {
                $script:LogPath = Join-Path $TestDrive 'test.log'
            }
        }

        It 'Should throw when mandatory parameters are missing' -Skip {
            # This test is skipped because it causes interactive prompts during build
            { Copy-BPERPDashboardFiles } | Should -Throw
        }

        It 'Should copy dashboard files when config is valid' {
            Mock -CommandName Test-Path -ModuleName BPC.DBRefresh -MockWith { $true }
            Mock -CommandName Copy-Item -ModuleName BPC.DBRefresh -MockWith { }
            Mock -CommandName New-Item -ModuleName BPC.DBRefresh -MockWith { }
            Mock -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -MockWith { }
            
            $config = @{
                DashboardSourcePath = $sourcePath
                DashboardDestinationPath = $destPath
                Servers = @('TestServer')
            }
            
            Copy-BPERPDashboardFiles -Config $config
            
            Assert-MockCalled -CommandName Copy-Item -ModuleName BPC.DBRefresh -Times 1
        }

        It 'Should skip when dashboard paths not configured' {
            Mock -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -MockWith { }
            
            $config = @{}
            
            Copy-BPERPDashboardFiles -Config $config
            
            Assert-MockCalled -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -ParameterFilter { $Level -eq 'Warning' }
        }

        It 'Should handle missing source path' {
            Mock -CommandName Test-Path -ModuleName BPC.DBRefresh -MockWith { $false }
            Mock -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -MockWith { }
            
            $config = @{
                DashboardSourcePath = 'C:\NonExistent'
                DashboardDestinationPath = $destPath
            }
            
            Copy-BPERPDashboardFiles -Config $config
            
            Assert-MockCalled -CommandName Write-BPERPLog -ModuleName BPC.DBRefresh -ParameterFilter { $Level -eq 'Warning' }
        }
    }

    Context 'Help documentation' {
        It 'Should have help documentation' {
            $help = Get-Help Copy-BPERPDashboardFiles -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It 'Should have parameter help for all parameters' {
            $help = Get-Help Copy-BPERPDashboardFiles -Parameter Config
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It 'Should have at least one example' {
            $help = Get-Help Copy-BPERPDashboardFiles -Examples
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}