#Requires -Version 5.1
#Requires -Modules PSLogging, dbatools, PsIni

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile "$ModuleRoot\BPlusDBRestore.psd1").ModuleVersion
$script:LogPath = $null

# Import private functions
$Private = @(Get-ChildItem -Path "$ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($import in $Private) {
  try {
    . $import.FullName
    Write-Verbose "Imported private function: $($import.BaseName)"
  }
  catch {
    Write-Error "Failed to import private function $($import.FullName): $_"
    throw
  }
}

# Import public functions
$Public = @(Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($import in $Public) {
  try {
    . $import.FullName
    Write-Verbose "Imported public function: $($import.BaseName)"
  }
  catch {
    Write-Error "Failed to import public function $($import.FullName): $_"
    throw
  }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Module initialization
Write-Verbose "BPlusDBRestore module v$($script:ModuleVersion) loaded successfully"