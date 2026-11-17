#Requires -RunAsAdministrator

$qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
if (-not (Test-Path $qosPath)) {
    New-Item -Path $qosPath -Force | Out-Null
}

# Set reservable bandwidth limit to 0%
Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force

Write-Host "QoS reservable bandwidth limit set to 0%." -ForegroundColor Green
