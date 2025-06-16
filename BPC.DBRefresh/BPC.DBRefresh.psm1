# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile (Join-Path $PSScriptRoot "BPC.DBRefresh.psd1")).ModuleVersion
$script:LogPath = $null

# Dot source public/private functions
$classes = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes/*.ps1') -Recurse -ErrorAction Stop)
$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public/*.ps1')  -Recurse -ErrorAction Stop)
$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private/*.ps1') -Recurse -ErrorAction Stop)
foreach ($import in @($classes + $public + $private)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

Export-ModuleMember -Function 'Copy-BPERPDashboardFiles', 'Get-BPERPDatabaseSettings', 'Restart-BPERPServers', 'Invoke-BPERPDatabaseRestore', 'Invoke-BPERPDatabaseRestoreFiles', 'Send-BPERPNotification', 'Set-BPERPConfiguration', 'Set-BPERPDatabasePermissions', 'Set-BPERPDatabaseSettings', 'Stop-BPERPServices'