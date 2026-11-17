$kbdPath = "HKCU:\Control Panel\Keyboard"

# Set shortest delay before repeat (0 = shortest, 3 = longest)
Set-ItemProperty -Path $kbdPath -Name "KeyboardDelay" -Value "0" -Type String -Force

# Set fastest character repeat rate (31 = fastest, 0 = slowest)
Set-ItemProperty -Path $kbdPath -Name "KeyboardSpeed" -Value "31" -Type String -Force

Write-Host "Keyboard repeat delay and speed optimized. Relog or reboot to apply." -ForegroundColor Green
