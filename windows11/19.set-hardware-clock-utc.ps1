#Requires -RunAsAdministrator

$tzPath = "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation"

# Force Windows to use UTC for the motherboard hardware clock (RealTimeIsUniversal = 1)
Set-ItemProperty -Path $tzPath -Name "RealTimeIsUniversal" -Value 1 -Type DWord -Force

# Resync Windows Time service immediately
Restart-Service w32time -ErrorAction SilentlyContinue
w32tm /resync /force | Out-Null

Write-Host "Hardware clock set to UTC. Time synced." -ForegroundColor Green
