#Requires -RunAsAdministrator

Write-Host "Disabling power management on all USB hubs and HID devices..." -ForegroundColor Cyan

$usbDevices = Get-PnpDevice -Class "USB", "HIDClass" -Status "OK" -ErrorAction SilentlyContinue

foreach ($dev in $usbDevices) {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "EnhancedPowerManagementEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $regPath -Name "AllowIdleIrpInD3" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "USB and HID device power saving disabled. Reboot to apply." -ForegroundColor Green
