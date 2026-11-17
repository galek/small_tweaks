#Requires -RunAsAdministrator

Write-Host "Disabling diagnostic ETW AutoLoggers..." -ForegroundColor Cyan

$autoLoggers = @(
    "CloudExperienceHostOobe",
    "DefenderApiLogger",
    "DefenderAuditLogger",
    "DiagLog",
    "ReadyBoot",
    "SqmLogger",
    "WdiContextLog",
    "WiFiSession"
)

$basePath = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger"

foreach ($logger in $autoLoggers) {
    $loggerPath = Join-Path $basePath $logger
    if (Test-Path $loggerPath) {
        Set-ItemProperty -Path $loggerPath -Name "Start" -Value 0 -Type DWord -Force
        Write-Host "Disabled AutoLogger: $logger" -ForegroundColor DarkGray
    }
}

Write-Host "Diagnostic AutoLoggers disabled. Reboot to apply." -ForegroundColor Green
