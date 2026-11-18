# Ensure the script runs with Administrator privileges to read all services, tasks, and driver folders
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Write-NvAuditRow {
    param (
        [string]$Category,
        [string]$Name,
        [bool]$IsClean,
        [string]$Details
    )
    $StatusText = if ($IsClean) { "[DISABLED / CLEAN]  " } else { "[ACTIVE / PRESENT]  " }
    $Color = if ($IsClean) { "Green" } else { "Yellow" }
    Write-Host ("{0,-15} | {1,-38} | {2} | {3}" -f $Category, $Name, $StatusText, $Details) -ForegroundColor $Color
}

Write-Host "=== NVIDIA Telemetry & Background Services Audit ===" -ForegroundColor Cyan
Write-Host ("{0,-15} | {1,-38} | {2,-20} | {3}" -f "Category", "Component", "Status", "Current Value") -ForegroundColor Gray
Write-Host ("-" * 105) -ForegroundColor Gray

# 1. Check NVIDIA Services (Telemetry vs Core Display)
$NvServices = @(
    @{ Name = "NvTelemetryContainer"; Label = "NVIDIA Telemetry Container"; MustBeDisabled = $true },
    @{ Name = "NVDisplay.ContainerLocalSystem"; Label = "NVIDIA Display Container (Core)"; MustBeDisabled = $false },
    @{ Name = "FvSvc"; Label = "NVIDIA FrameView SDK Service"; MustBeDisabled = $true }
)

foreach ($Svc in $NvServices) {
    $ServiceObj = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if ($ServiceObj) {
        if ($Svc.MustBeDisabled) {
            $IsClean = ($ServiceObj.StartType -eq 'Disabled') -and ($ServiceObj.Status -eq 'Stopped')
        } else {
            # Core display container should remain active for Control Panel / RTX features
            $IsClean = ($ServiceObj.Status -eq 'Running')
        }
        Write-NvAuditRow -Category "Service" -Name $Svc.Label -IsClean $IsClean -Details "Start: $($ServiceObj.StartType), State: $($ServiceObj.Status)"
    } else {
        Write-NvAuditRow -Category "Service" -Name $Svc.Label -IsClean $true -Details "Service not installed"
    }
}

# 2. Check NVIDIA Scheduled Tasks (Crash Reporters & Monitors)
$NvTasks = Get-ScheduledTask -TaskName "NvTmRep*", "NvTmMon*", "NvProfileUpdater*" -ErrorAction SilentlyContinue
if ($NvTasks) {
    foreach ($Task in $NvTasks) {
        $IsTaskDisabled = ($Task.State -eq 'Disabled')
        Write-NvAuditRow -Category "Scheduled Task" -Name $Task.TaskName -IsClean $IsTaskDisabled -Details "State: $($Task.State)"
    }
} else {
    Write-NvAuditRow -Category "Scheduled Task" -Name "NVIDIA Telemetry Tasks (NvTm*)" -IsClean $true -Details "No telemetry tasks found"
}

# 3. Check NVIDIA Telemetry Registry Opt-Out Keys
$NvRegChecks = @(
    @{ Label = "NvTelemetry EnableTelemetry"; Path = "HKLM:\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client"; Name = "OptInOrOutPreference"; Expected = 0 },
    @{ Label = "NvTelemetry Global Disable"; Path = "HKLM:\SYSTEM\CurrentControlSet\Services\NvTelemetryContainer"; Name = "Start"; Expected = 4 }
)

foreach ($Reg in $NvRegChecks) {
    $Val = (Get-ItemProperty -Path $Reg.Path -Name $Reg.Name -ErrorAction SilentlyContinue).($Reg.Name)
    if ($null -ne $Val) {
        $IsMatched = ($Val -eq $Reg.Expected)
        Write-NvAuditRow -Category "Registry" -Name $Reg.Label -IsClean $IsMatched -Details "Value: $Val (Expected: $($Reg.Expected))"
    } else {
        Write-NvAuditRow -Category "Registry" -Name $Reg.Label -IsClean $true -Details "Key/Value not present"
    }
}

# 4. Check Embedded Telemetry DLLs in NVIDIA DriverStore / Program Files
$SearchPaths = @(
    "$env:ProgramFiles\NVIDIA Corporation",
    "$env:SystemRoot\System32\DriverStore\FileRepository"
)

$FoundDlls = @()
foreach ($Path in $SearchPaths) {
    if (Test-Path $Path) {
        $FoundDlls += Get-ChildItem -Path $Path -Filter "*NvTelemetry*.dll" -Recurse -ErrorAction SilentlyContinue
    }
}

if ($FoundDlls.Count -gt 0) {
    Write-NvAuditRow -Category "Driver DLLs" -Name "Embedded NvTelemetry*.dll" -IsClean $false -Details "Found $($FoundDlls.Count) telemetry DLL(s)"
} else {
    Write-NvAuditRow -Category "Driver DLLs" -Name "Embedded NvTelemetry*.dll" -IsClean $true -Details "No telemetry DLLs found"
}

# 5. Check Running NVIDIA Background Processes
$RunningNvProcs = Get-Process -Name "NvTelemetry*", "NVIDIA Share", "nvsphelper64", "NVIDIA Overlay" -ErrorAction SilentlyContinue
if ($RunningNvProcs) {
    $ProcNames = ($RunningNvProcs.Name | Select-Object -Unique) -join ", "
    Write-NvAuditRow -Category "Processes" -Name "Extra NVIDIA Background Procs" -IsClean $false -Details "Running: $ProcNames"
} else {
    Write-NvAuditRow -Category "Processes" -Name "Extra NVIDIA Background Procs" -IsClean $true -Details "None running"
}

Write-Host ("-" * 105) -ForegroundColor Gray
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
