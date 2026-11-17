#Requires -RunAsAdministrator

$devPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $devPath)) {
    New-Item -Path $devPath -Force | Out-Null
}

# Enable Developer Mode and Sideloading
Set-ItemProperty -Path $devPath -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $devPath -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force

Write-Host "Windows Developer Mode enabled successfully." -ForegroundColor Green
