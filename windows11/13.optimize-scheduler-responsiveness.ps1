#Requires -RunAsAdministrator

Write-Host "Cleaning temporary files, update cache, and Recycle Bin..." -ForegroundColor Cyan

# 1. Clean user and system Temp folders
$tempFolders = @($env:TEMP, "C:\Windows\Temp")
foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 2. Clean Windows Update download cache
Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
$wuDownload = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $wuDownload) {
    Get-ChildItem -Path $wuDownload -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue

# 3. Clean Delivery Optimization cache
Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue

# 4. Empty Recycle Bin on all drives
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host "System cleanup completed successfully." -ForegroundColor Green
