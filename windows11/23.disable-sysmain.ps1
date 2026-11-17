#Requires -RunAsAdministrator

Write-Host "Disabling SysMain (Superfetch) service..." -ForegroundColor Cyan

if (Get-Service -Name "SysMain" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled
}

Write-Host "SysMain service disabled successfully." -ForegroundColor Green
