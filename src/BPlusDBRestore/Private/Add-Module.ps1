function Add-Module {
  <#
  .SYNOPSIS
      Checks for and imports required PowerShell modules
  
  .DESCRIPTION
      Verifies that a PowerShell module is available and imports it.
      If the module is not found, it attempts to install it.
  
  .PARAMETER Name
      The name of the module to import
  
  .EXAMPLE
      Add-Module -Name 'dbatools'
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (Get-Module -Name $Name -ListAvailable) {
    try {
      Import-Module -Name $Name -Force -ErrorAction Stop
      Write-Verbose "Successfully imported module: $Name"
    }
    catch {
      throw "Failed to import module $Name : $_"
    }
  }
  else {
    throw "Module $Name is not installed. Please install it using: Install-Module -Name $Name"
  }
}