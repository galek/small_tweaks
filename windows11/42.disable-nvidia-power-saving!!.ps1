# FOR modificated RTX2080 8 to 16gb

#Requires -RunAsAdministrator

Write-Host "Disabling NVIDIA driver dynamic P-State switching..." -ForegroundColor Cyan

$displayClassPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"

Get-ChildItem -Path $displayClassPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
    $desc = (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue).DriverDesc
    if ($desc -like "*NVIDIA*") {
        Set-ItemProperty -Path $_.PSPath -Name "DisableDynamicPstate" -Value 1 -Type DWord -Force
        Write-Host "Disabled dynamic P-States for: $desc" -ForegroundColor DarkGray
    }
}

Write-Host "NVIDIA P-State power saving disabled. Reboot to apply." -ForegroundColor Green
