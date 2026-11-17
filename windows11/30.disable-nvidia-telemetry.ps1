#Requires -RunAsAdministrator

Write-Host "Disabling NVIDIA telemetry services and scheduled tasks..." -ForegroundColor Cyan

# Disable NVIDIA Telemetry Container service if present
if (Get-Service -Name "NvTelemetryContainer" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "NvTelemetryContainer" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "NvTelemetryContainer" -StartupType Disabled
}

# Disable NVIDIA telemetry scheduled tasks
Get-ScheduledTask | Where-Object { $_.TaskName -like "*NvTmMon*" -or $_.TaskName -like "*NvTmRep*" -or $_.TaskName -like "*NvProfileUpdater*" } | ForEach-Object {
    Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
    Write-Host "Disabled NVIDIA task: $($_.TaskName)" -ForegroundColor DarkGray
}

Write-Host "NVIDIA telemetry disabled successfully." -ForegroundColor Green
