#Requires -RunAsAdministrator

$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

# Disable multimedia network throttling (0xFFFFFFFF = Disabled)
Set-ItemProperty -Path $path -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force

Write-Host "Network Throttling Index has been disabled. Reboot to apply." -ForegroundColor Green
