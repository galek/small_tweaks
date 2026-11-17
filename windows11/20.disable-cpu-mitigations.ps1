#Requires -RunAsAdministrator

$mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

# Disable Spectre and Meltdown OS-level mitigations
Set-ItemProperty -Path $mmPath -Name "FeatureSettingsOverride" -Value 3 -Type DWord -Force
Set-ItemProperty -Path $mmPath -Name "FeatureSettingsOverrideMask" -Value 3 -Type DWord -Force

Write-Host "CPU Spectre/Meltdown mitigations disabled. Reboot to apply." -ForegroundColor Green
