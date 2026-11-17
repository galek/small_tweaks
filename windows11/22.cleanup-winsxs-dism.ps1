#Requires -RunAsAdministrator

Write-Host "Cleaning up superseded Windows component store files (WinSxS)..." -ForegroundColor Cyan

# Run DISM component cleanup with ResetBase to permanently remove old update backups
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase

Write-Host "WinSxS component cleanup completed successfully." -ForegroundColor Green
