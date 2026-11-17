#Requires -RunAsAdministrator

Write-Host "Disabling LLMNR and NetBIOS over TCP/IP..." -ForegroundColor Cyan

# Disable LLMNR via Group Policy
$dnsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (-not (Test-Path $dnsPolicyPath)) {
    New-Item -Path $dnsPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $dnsPolicyPath -Name "EnableMulticast" -Value 0 -Type DWord -Force

# Disable NetBIOS over TCP/IP (2 = Disable) on all network adapters
$netbtPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
Get-ChildItem -Path $netbtPath | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Type DWord -Force
}

Write-Host "LLMNR and NetBIOS disabled successfully." -ForegroundColor Green
