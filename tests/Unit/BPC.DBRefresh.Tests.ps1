# Tests for BPC.DBRefresh module

Describe "BPC.DBRefresh Module Tests" {
  
  Context "Module Structure" {
    BeforeAll {
      $script:here = $PSScriptRoot
      if (-not $script:here) {
        $script:here = Split-Path -Parent $MyInvocation.MyCommand.Path
      }
      
      # Get paths using cross-platform approach
      $script:ModuleRoot = Join-Path -Path $script:here -ChildPath ".." | 
                           Join-Path -ChildPath ".." | 
                           Join-Path -ChildPath "src" | 
                           Join-Path -ChildPath "BPC.DBRefresh" |
                           Resolve-Path
    }
    
    It "Should have a module manifest" {
      $manifestPath = Join-Path $script:ModuleRoot "BPC.DBRefresh.psd1"
      Test-Path $manifestPath | Should -Be $true
    }
    
    It "Should have a valid module manifest" {
      $manifestPath = Join-Path $script:ModuleRoot "BPC.DBRefresh.psd1"
      { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }
    
    It "Should have a module file" {
      $modulePath = Join-Path $script:ModuleRoot "BPC.DBRefresh.psm1"
      Test-Path $modulePath | Should -Be $true
    }
    
    It "Should have Private functions directory" {
      $privatePath = Join-Path $script:ModuleRoot "Private"
      Test-Path $privatePath | Should -Be $true
    }
    
    It "Should have Public functions directory" {
      $publicPath = Join-Path $script:ModuleRoot "Public"
      Test-Path $publicPath | Should -Be $true
    }
  }
  
  Context "Module Manifest Content" {
    BeforeAll {
      $script:here = $PSScriptRoot
      if (-not $script:here) {
        $script:here = Split-Path -Parent $MyInvocation.MyCommand.Path
      }
      
      $script:ModuleRoot = Join-Path -Path $script:here -ChildPath ".." | 
                           Join-Path -ChildPath ".." | 
                           Join-Path -ChildPath "src" | 
                           Join-Path -ChildPath "BPC.DBRefresh" |
                           Resolve-Path
                           
      $manifestPath = Join-Path $script:ModuleRoot "BPC.DBRefresh.psd1"
      $script:manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    }
    
    It "Should have correct module version" {
      $script:manifest.Version | Should -Not -BeNullOrEmpty
      $script:manifest.Version.Major | Should -BeGreaterOrEqual 1
    }
    
    It "Should have correct PowerShell version requirement" {
      $script:manifest.PowerShellVersion | Should -Be '5.1'
    }
    
    It "Should have author defined" {
      $script:manifest.Author | Should -Not -BeNullOrEmpty
    }
    
    It "Should have description defined" {
      $script:manifest.Description | Should -Not -BeNullOrEmpty
    }
    
    It "Should export expected functions" {
      $expectedFunctions = @(
        'Invoke-BPERPDatabaseRestore'
        'Stop-BPERPServices'
        'Get-BPERPDatabaseSettings'
        'Invoke-BPERPDatabaseRestoreFiles'
        'Set-BPERPDatabaseSettings'
        'Set-BPERPDatabasePermissions'
        'Set-BPERPConfiguration'
        'Copy-BPERPDashboardFiles'
        'Restart-BPERPServers'
        'Send-BPERPNotification'
      )
      
      # Read the manifest file directly to check FunctionsToExport
      $manifestPath = Join-Path $script:ModuleRoot "BPC.DBRefresh.psd1"
      $manifestContent = Import-PowerShellDataFile $manifestPath
      
      foreach ($func in $expectedFunctions) {
        $manifestContent.FunctionsToExport | Should -Contain $func
      }
    }
    
    It "Should have required modules defined" {
      $script:manifest.RequiredModules | Should -Not -BeNullOrEmpty
      $requiredModuleNames = $script:manifest.RequiredModules | ForEach-Object { $_.Name }
      $requiredModuleNames | Should -Contain 'PSLogging'
      $requiredModuleNames | Should -Contain 'dbatools'
      $requiredModuleNames | Should -Contain 'PsIni'
    }
  }
  
  Context "Public Functions" {
    BeforeAll {
      $script:here = $PSScriptRoot
      if (-not $script:here) {
        $script:here = Split-Path -Parent $MyInvocation.MyCommand.Path
      }
      
      $script:ModuleRoot = Join-Path -Path $script:here -ChildPath ".." | 
                           Join-Path -ChildPath ".." | 
                           Join-Path -ChildPath "src" | 
                           Join-Path -ChildPath "BPC.DBRefresh" |
                           Resolve-Path
                           
      $script:PublicPath = Join-Path $script:ModuleRoot "Public"
    }
    
    It "Should have Invoke-BPERPDatabaseRestore.ps1" {
      $functionPath = Join-Path $script:PublicPath "Invoke-BPERPDatabaseRestore.ps1"
      Test-Path $functionPath | Should -Be $true
    }
    
    It "Should have Stop-BPERPServices.ps1" {
      $functionPath = Join-Path $script:PublicPath "Stop-BPERPServices.ps1"
      Test-Path $functionPath | Should -Be $true
    }
    
    It "Should have all expected public function files" {
      $expectedFiles = @(
        'Invoke-BPERPDatabaseRestore.ps1'
        'Stop-BPERPServices.ps1'
        'Get-BPERPDatabaseSettings.ps1'
        'Invoke-BPERPDatabaseRestoreFiles.ps1'
        'Set-BPERPDatabaseSettings.ps1'
        'Set-BPERPDatabasePermissions.ps1'
        'Set-BPERPConfiguration.ps1'
        'Copy-BPERPDashboardFiles.ps1'
        'Restart-BPERPServers.ps1'
        'Send-BPERPNotification.ps1'
      )
      
      $actualFiles = Get-ChildItem -Path $script:PublicPath -Filter "*.ps1" | Select-Object -ExpandProperty Name
      
      foreach ($file in $expectedFiles) {
        $actualFiles | Should -Contain $file
      }
    }
  }
  
  Context "Private Functions" {
    BeforeAll {
      $script:here = $PSScriptRoot
      if (-not $script:here) {
        $script:here = Split-Path -Parent $MyInvocation.MyCommand.Path
      }
      
      $script:ModuleRoot = Join-Path -Path $script:here -ChildPath ".." | 
                           Join-Path -ChildPath ".." | 
                           Join-Path -ChildPath "src" | 
                           Join-Path -ChildPath "BPC.DBRefresh" |
                           Resolve-Path
                           
      $script:PrivatePath = Join-Path $script:ModuleRoot "Private"
    }
    
    It "Should have Add-Module.ps1" {
      $functionPath = Join-Path $script:PrivatePath "Add-Module.ps1"
      Test-Path $functionPath | Should -Be $true
    }
    
    It "Should have expected private function files" {
      $expectedFiles = @(
        'Add-Module.ps1'
        'Build-EmailHTML.ps1'
        'Get-BPlusEnvironmentConfig.ps1'
        'Show-BPlusConfiguration.ps1'
        'Write-BPlusLog.ps1'
      )
      
      $actualFiles = Get-ChildItem -Path $script:PrivatePath -Filter "*.ps1" | Select-Object -ExpandProperty Name
      
      foreach ($file in $expectedFiles) {
        $actualFiles | Should -Contain $file
      }
    }
  }
}