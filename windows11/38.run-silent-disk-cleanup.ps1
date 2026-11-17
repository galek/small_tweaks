#Requires -RunAsAdministrator

Write-Host "Configuring and running silent Windows Disk Cleanup..." -ForegroundColor Cyan

$volumeCachesPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$cleanupCategories = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "D3D Shader Cache",
    "Delivery Optimization Files",
    "Downloaded Program Files",
    "Internet Cache Files",
    "Old ChkDsk Files",
    "Recycle Bin",
    "Setup Log Files",
    "System error memory dump files",
    "System error minidump files",
    "Temporary Files",
    "Temporary Setup Files",
    "Thumbnail Cache",
    "Update Cleanup",
    "Windows Defender",
    "Windows Error Reporting Files",
    "Windows Upgrade Log Files"
)

# Enable StateFlags0099 (value 2) for each selected cleanup category
foreach ($category in $cleanupCategories) {
    $catPath = Join-Path $volumeCachesPath $category
    if (Test-Path $catPath) {
        Set-ItemProperty -Path $catPath -Name "StateFlags0099" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

# Run cleanmgr silently using profile 99 and wait for completion
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:99" -WindowStyle Hidden -Wait

Write-Host "Silent Disk Cleanup completed successfully." -ForegroundColor Green
