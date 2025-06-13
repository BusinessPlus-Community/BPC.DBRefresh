<#
.SYNOPSIS
    Complete example with all options including dashboard restoration

.DESCRIPTION
    This example shows a full environment refresh including:
    - All three databases (IFAS, SYSCAT, ASPNET)
    - Testing mode for additional accounts
    - Dashboard file restoration

.NOTES
    This is the most comprehensive restore option and may take considerable time
    depending on database sizes and network speed.
#>

# Import required modules
Import-Module BPC.DBRefresh -ErrorAction Stop

# Set up logging for this session
$logPath = "C:\Logs\BPlusRestore"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

$date = Get-Date -Format "yyyyMMdd_HHmmss"
$sessionLog = Join-Path $logPath "FullRestore_$date.log"

# Start transcript
Start-Transcript -Path $sessionLog

try {
    # Define all parameters
    $restoreParams = @{
        BPEnvironment     = "DEV"
        ifasFilePath      = "\\backup-server\backups\IFAS_PROD_20240115.bak"
        syscatFilePath    = "\\backup-server\backups\SYSCAT_PROD_20240115.bak"
        aspnetFilePath    = "\\backup-server\backups\ASPNET_PROD_20240115.bak"
        testingMode       = $true   # Enable additional test accounts
        restoreDashboards = $true   # Copy dashboard files
    }

    # Show what we're about to do
    Write-Host "Starting full environment restore with the following settings:" -ForegroundColor Cyan
    $restoreParams.GetEnumerator() | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
    }
    
    # Get confirmation in interactive mode
    if ($Host.UI.PromptForChoice("Confirm", "Proceed with full restore?", @("&Yes", "&No"), 1) -eq 0) {
        # Perform the restore
        Invoke-BPERPDatabaseRestore @restoreParams
        
        Write-Host "`nFull environment restore completed successfully!" -ForegroundColor Green
        
        # Additional post-restore tasks could go here
        Write-Host "`nPost-restore recommendations:" -ForegroundColor Yellow
        Write-Host "1. Verify services are running on all servers" -ForegroundColor Gray
        Write-Host "2. Test application login with a manager account" -ForegroundColor Gray
        Write-Host "3. Verify dashboard accessibility" -ForegroundColor Gray
        Write-Host "4. Check email configuration is pointing to test SMTP" -ForegroundColor Gray
    }
    else {
        Write-Host "Restore cancelled by user." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Restore failed: $_"
    throw
}
finally {
    Stop-Transcript
    Write-Host "`nSession log saved to: $sessionLog" -ForegroundColor Cyan
}