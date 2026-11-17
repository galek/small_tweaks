#Requires -RunAsAdministrator

# Completely disable Hyper-V hypervisor at boot for pure bare-metal performance
bcdedit /set hypervisorlaunchtype off | Out-Null

Write-Host "Hypervisor disabled at boot (Bare-Metal mode). Reboot required to apply." -ForegroundColor Green
