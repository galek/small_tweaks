# Ensure the script runs with Administrator privileges to read all registry keys and tasks
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Write-AuditRow {
    param (
        [string]$Category,
        [string]$Name,
        [bool]$IsTweaked,
        [string]$Details
    )
    $StatusText = if ($IsTweaked) { "[DISABLED / TWEAKED]" } else { "[ACTIVE / DEFAULT]  " }
    $Color = if ($IsTweaked) { "Green" } else { "Yellow" }
    Write-Host ("{0,-15} | {1,-38} | {2} | {3}" -f $Category, $Name, $StatusText, $Details) -ForegroundColor $Color
}

Write-Host "=== Deep Telemetry, AutoLoggers & AI Audit ===" -ForegroundColor Cyan
Write-Host ("{0,-15} | {1,-38} | {2,-20} | {3}" -f "Category", "Component", "Status", "Current Value") -ForegroundColor Gray
Write-Host ("-" * 105) -ForegroundColor Gray

# 1. Check Kernel AutoLogger Telemetry Sessions
$AutoLoggers = @(
    "AutoLogger-Diagtrack-Listener",
    "DiagLog",
    "WdiContextLog",
    "SQMLogger"
)

foreach ($Logger in $AutoLoggers) {
    $LoggerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\$Logger"
    if (Test-Path $LoggerPath) {
        $StartVal = (Get-ItemProperty -Path $LoggerPath -Name "Start" -ErrorAction SilentlyContinue).Start
        $IsDisabled = ($StartVal -eq 0)
        $DetailStr = if ($null -eq $StartVal) { "Start value not set" } else { "Start: $StartVal" }
        Write-AuditRow -Category "AutoLogger" -Name $Logger -IsTweaked $IsDisabled -Details $DetailStr
    } else {
        Write-AuditRow -Category "AutoLogger" -Name $Logger -IsTweaked $true -Details "Key not found"
    }
}

# 3. Check Additional Hidden Windows Telemetry Tasks
$ExtraTasks = @(
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

foreach ($Task in $ExtraTasks) {
    $TaskObj = Get-ScheduledTask -TaskPath $Task.Path -TaskName $Task.Name -ErrorAction SilentlyContinue
    if ($TaskObj) {
        $IsTaskDisabled = ($TaskObj.State -eq 'Disabled')
        Write-AuditRow -Category "Hidden Task" -Name $Task.Name -IsTweaked $IsTaskDisabled -Details "State: $($TaskObj.State)"
    } else {
        Write-AuditRow -Category "Hidden Task" -Name $Task.Name -IsTweaked $true -Details "Task not found"
    }
}

# 4. Check Program Compatibility Assistant Service (PcaSvc)
$PcaService = Get-Service -Name "PcaSvc" -ErrorAction SilentlyContinue
if ($PcaService) {
    $IsPcaDisabled = ($PcaService.StartType -eq 'Disabled') -and ($PcaService.Status -eq 'Stopped')
    Write-AuditRow -Category "Service" -Name "Program Compatibility (PcaSvc)" -IsTweaked $IsPcaDisabled -Details "Start: $($PcaService.StartType), State: $($PcaService.Status)"
} else {
    Write-AuditRow -Category "Service" -Name "Program Compatibility (PcaSvc)" -IsTweaked $true -Details "Service not found"
}

# 5. Check Windows Copilot & Recall / Windows AI Policies
$AiChecks = @(
    @{ Label = "Windows Copilot Policy"; Path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Expected = 1 },
    @{ Label = "Windows AI / Recall Policy"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Expected = 1 }
)

foreach ($Policy in $AiChecks) {
    $Val = (Get-ItemProperty -Path $Policy.Path -Name $Policy.Name -ErrorAction SilentlyContinue).($Policy.Name)
    $IsMatched = ($null -ne $Val) -and ($Val -eq $Policy.Expected)
    $DisplayVal = if ($null -eq $Val) { "Not Set (Default)" } else { "Value: $Val" }
    Write-AuditRow -Category "AI Policy" -Name $Policy.Label -IsTweaked $IsMatched -Details $DisplayVal
}

Write-Host ("-" * 105) -ForegroundColor Gray
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
