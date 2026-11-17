#Requires -RunAsAdministrator

# Get all active physical/virtual network adapters
$activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false }

# Define DNS servers (Primary: Cloudflare, Secondary: Google)
$ipv4Dns = @("1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4")
$ipv6Dns = @("2606:4700:4700::1111", "2606:4700:4700::1001", "2001:4860:4860::8888")

foreach ($adapter in $activeAdapters) {
    Write-Host "Configuring DNS for adapter: $($adapter.Name)..." -ForegroundColor Cyan
    
    # Set custom IPv4 and IPv6 DNS addresses
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ($ipv4Dns + $ipv6Dns)
    
    # To revert back to automatic (DHCP) DNS later, uncomment the line below:
    # Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
}

# Flush local DNS resolver cache
Clear-DnsClientCache
Write-Host "DNS servers updated and cache flushed successfully." -ForegroundColor Green
