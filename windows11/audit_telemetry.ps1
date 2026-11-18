# Ensure the script runs with Administrator privileges to read all registry keys and services
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Write-CheckResult {
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

Write-Host "=== Windows 11 System Tweaks & Telemetry Audit ===" -ForegroundColor Cyan
Write-Host ("{0,-15} | {1,-38} | {2,-20} | {3}" -f "Category", "Component", "Status", "Current Value") -ForegroundColor Gray
Write-Host ("-" * 105) -ForegroundColor Gray

# 1. Check System Services
$ServicesToCheck = @(
    @{ Name = "DiagTrack"; Label = "Telemetry (DiagTrack)" },
    @{ Name = "dmwappushservice"; Label = "WAP Push Telemetry" },
    @{ Name = "WSearch"; Label = "Windows Search Indexer" },
    @{ Name = "SysMain"; Label = "SysMain (Superfetch)" },
    @{ Name = "WerSvc"; Label = "Windows Error Reporting" },
    @{ Name = "DPS"; Label = "Diagnostic Policy Service" },
    @{ Name = "MapsBroker"; Label = "Downloaded Maps Manager" }
)

foreach ($Svc in $ServicesToCheck) {
    $ServiceObj = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if ($ServiceObj) {
        $IsDisabled = ($ServiceObj.StartType -eq 'Disabled') -and ($ServiceObj.Status -eq 'Stopped')
        Write-CheckResult -Category "Service" -Name $Svc.Label -IsTweaked $IsDisabled -Details "Start: $($ServiceObj.StartType), State: $($ServiceObj.Status)"
    } else {
        Write-CheckResult -Category "Service" -Name $Svc.Label -IsTweaked $true -Details "Service not found"
    }
}

# 2. Check Image File Execution Options (Blocked Executables)
$BlockedExes = @("msedgewebview2.exe", "CompatTelRunner.exe", "DeviceCensus.exe")
foreach ($Exe in $BlockedExes) {
    $IfEoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$Exe"
    $DebuggerVal = (Get-ItemProperty -Path $IfEoPath -Name "Debugger" -ErrorAction SilentlyContinue).Debugger
    $IsBlocked = -not [string]::IsNullOrEmpty($DebuggerVal)
    $DetailStr = if ($IsBlocked) { "Blocked via Debugger ($DebuggerVal)" } else { "Not blocked" }
    Write-CheckResult -Category "IFEO Block" -Name $Exe -IsTweaked $IsBlocked -Details $DetailStr
}

# 3. Check Scheduled Tasks (Telemetry)
$TasksToCheck = @(
    @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
    @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
    @{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy" }
)

foreach ($Task in $TasksToCheck) {
    $TaskObj = Get-ScheduledTask -TaskPath $Task.Path -TaskName $Task.Name -ErrorAction SilentlyContinue
    if ($TaskObj) {
        $IsTaskDisabled = ($TaskObj.State -eq 'Disabled')
        Write-CheckResult -Category "Task Scheduler" -Name $Task.Name -IsTweaked $IsTaskDisabled -Details "State: $($TaskObj.State)"
    } else {
        Write-CheckResult -Category "Task Scheduler" -Name $Task.Name -IsTweaked $true -Details "Task not found"
    }
}

# 4. Check Windows Defender Status
$DefenderService = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
$MpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($MpStatus) {
    $DefDisabled = (-not $MpStatus.RealTimeProtectionEnabled)
    Write-CheckResult -Category "Security" -Name "Windows Defender Real-Time" -IsTweaked $DefDisabled -Details "RealTimeEnabled: $($MpStatus.RealTimeProtectionEnabled)"
} else {
    $SvcState = if ($DefenderService) { $DefenderService.Status } else { "Missing/Disabled" }
    Write-CheckResult -Category "Security" -Name "Windows Defender Service" -IsTweaked $true -Details "Status: $SvcState"
}

# 5. Check Registry Tweaks (Privacy, UI, Power, Network)
$RegChecks = @(
    @{ Label = "Telemetry Level (AllowTelemetry)"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Expected = 0 },
    @{ Label = "Advertising ID"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Expected = 0 },
    @{ Label = "Activity History"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed"; Expected = 0 },
    @{ Label = "Fast Startup (Hiberboot)"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name = "HiberbootEnabled"; Expected = 0 },
    @{ Label = "Hibernation File"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"; Name = "HibernateEnabled"; Expected = 0 },
    @{ Label = "Network Throttling Index"; Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "NetworkThrottlingIndex"; Expected = 4294967295 },
    @{ Label = "Delivery Optimization Mode"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"; Name = "DODownloadMode"; Expected = 0 }
)

foreach ($Reg in $RegChecks) {
    $Val = (Get-ItemProperty -Path $Reg.Path -Name $Reg.Name -ErrorAction SilentlyContinue).($Reg.Name)
    $IsMatched = ($null -ne $Val) -and ($Val -eq $Reg.Expected)
    $DisplayVal = if ($null -eq $Val) { "Not Set (Default)" } else { $Val }
    Write-CheckResult -Category "Registry" -Name $Reg.Label -IsTweaked $IsMatched -Details "Value: $DisplayVal"
}

# 6. Check Classic Context Menu (Win10 style)
$CtxPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
$HasClassicCtx = Test-Path $CtxPath
Write-CheckResult -Category "UI Tweak" -Name "Classic Win10 Context Menu" -IsTweaked $HasClassicCtx -Details $(if ($HasClassicCtx) { "Enabled" } else { "Win11 Default" })

# 7. Check Active Power Plan
$ActivePlan = powercfg /getactivescheme
Write-Host ("-" * 105) -ForegroundColor Gray
Write-Host "Active Power Plan: $ActivePlan" -ForegroundColor Cyan
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
