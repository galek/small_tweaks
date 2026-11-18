# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Disabling remaining hidden telemetry and diagnostic scheduled tasks..." -ForegroundColor Cyan

# List of active hidden tasks to disable
$TasksToDisable = @(
    @{ Path = "\Microsoft\Windows\Shell\"; Name = "FamilySafetyMonitor" },
    @{ Path = "\Microsoft\Windows\Shell\"; Name = "FamilySafetyRefreshTask" },
    @{ Path = "\Microsoft\Windows\Flighting\FeatureConfig\"; Name = "ReconcileFeatures" },
    @{ Path = "\Microsoft\Windows\Flighting\FeatureConfig\"; Name = "UsageDataFlushing" },
    @{ Path = "\Microsoft\Windows\Flighting\FeatureConfig\"; Name = "UsageDataReporting" },
    @{ Path = "\Microsoft\Windows\PI\"; Name = "Sqm-Tasks" },
    @{ Path = "\Microsoft\Windows\Power Efficiency Diagnostics\"; Name = "AnalyzeSystem" },
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient" },
    @{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload" }
)

foreach ($Task in $TasksToDisable) {
    $ExistingTask = Get-ScheduledTask -TaskPath $Task.Path -TaskName $Task.Name -ErrorAction SilentlyContinue
    if ($ExistingTask) {
        Disable-ScheduledTask -TaskPath $Task.Path -TaskName $Task.Name -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Disabled: $($Task.Name)" -ForegroundColor Green
    } else {
        Write-Host "Not found (skipped): $($Task.Name)" -ForegroundColor Gray
    }
}

Write-Host "`nAll hidden tasks have been processed." -ForegroundColor Cyan
Start-Sleep -Seconds 2
