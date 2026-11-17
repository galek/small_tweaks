#Requires -RunAsAdministrator

Write-Host "Disabling Windows Biometric Service and policies..." -ForegroundColor Cyan

# Disable Biometrics via Group Policy
$bioPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics"
if (-not (Test-Path $bioPolicy)) {
    New-Item -Path $bioPolicy -Force | Out-Null
}
Set-ItemProperty -Path $bioPolicy -Name "Enabled" -Value 0 -Type DWord -Force

# Stop and disable Windows Biometric Service (WbioSrvc)
if (Get-Service -Name "WbioSrvc" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "WbioSrvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "WbioSrvc" -StartupType Disabled
}

Write-Host "Windows Biometrics disabled successfully." -ForegroundColor Green
