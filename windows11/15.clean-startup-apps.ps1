#Requires -RunAsAdministrator

Write-Host "Cleaning unnecessary startup entries..." -ForegroundColor Cyan

# Remove OneDrive from current user startup
$hkcuRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (Get-ItemProperty -Path $hkcuRun -Name "OneDrive" -ErrorAction SilentlyContinue) {
    Remove-ItemProperty -Path $hkcuRun -Name "OneDrive" -Force
}

# Disable Edge background boost and startup boost
$edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePolicy)) {
    New-Item -Path $edgePolicy -Force | Out-Null
}
Set-ItemProperty -Path $edgePolicy -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $edgePolicy -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force

# Display remaining active startup items for review
Write-Host "Remaining startup items:" -ForegroundColor Yellow
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location | Format-Table -AutoSize

Write-Host "Startup cleanup completed." -ForegroundColor Green
