#Requires -RunAsAdministrator

Write-Host "Disabling Windows Pagefile completely..." -ForegroundColor Cyan

# 1. Disable automatic pagefile management
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
if ($cs.AutomaticManagedPagefile) {
    Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false }
}

# 2. Remove all configured pagefiles across all drives
$pagefiles = Get-CimInstance -ClassName Win32_PageFileSetting
if ($pagefiles) {
    $pagefiles | Remove-CimInstance
}

# 3. Clear PagingFiles registry key to ensure no pagefile is recreated on boot
$mmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $mmPath -Name "PagingFiles" -Value @() -Type MultiString -Force

Write-Host "Pagefile disabled. Please reboot your PC to delete pagefile.sys from disk." -ForegroundColor Green
