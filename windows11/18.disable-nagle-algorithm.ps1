#Requires -RunAsAdministrator

Write-Host "Disabling Nagle's Algorithm on active network interfaces..." -ForegroundColor Cyan

$interfacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
$activeGuids = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | Select-Object -ExpandProperty InterfaceGuid

foreach ($guid in $activeGuids) {
    $targetKey = Join-Path $interfacesPath $guid
    if (Test-Path $targetKey) {
        Set-ItemProperty -Path $targetKey -Name "TcpAckFrequency" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $targetKey -Name "TCPNoDelay" -Value 1 -Type DWord -Force
        Write-Host "Optimized TCP parameters for interface: $guid" -ForegroundColor DarkGray
    }
}

Write-Host "Nagle's Algorithm disabled. Reboot to apply." -ForegroundColor Green
