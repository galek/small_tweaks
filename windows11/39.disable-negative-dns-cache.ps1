#Requires -RunAsAdministrator

$dnsCachePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
if (-not (Test-Path $dnsCachePath)) {
    New-Item -Path $dnsCachePath -Force | Out-Null
}

# Set negative DNS cache TTL to 0 seconds (prevents caching failed lookups)
Set-ItemProperty -Path $dnsCachePath -Name "MaxNegativeCacheTtl" -Value 0 -Type DWord -Force

Clear-DnsClientCache
Write-Host "Negative DNS caching disabled and resolver cache flushed." -ForegroundColor Green
