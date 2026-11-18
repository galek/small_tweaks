# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Disabling all remaining telemetry, diagnostic services, and trackers..." -ForegroundColor Cyan

# 1. Stop and disable diagnostic, error reporting, and maps services
$Services = @("DPS", "WdiServiceHost", "WdiSystemHost", "MapsBroker", "WerSvc")
foreach ($Svc in $Services) {
    Stop-Service -Name $Svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $Svc -StartupType Disabled -ErrorAction SilentlyContinue
}

# 2. Block telemetry executables via Image File Execution Options (IFEO)
$ExesToBlock = @("CompatTelRunner.exe", "DeviceCensus.exe")
foreach ($Exe in $ExesToBlock) {
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$Exe"
    if (-not (Test-Path $RegPath)) {
        New-Item -Path $RegPath -Force | Out-Null
    }
    New-ItemProperty -Path $RegPath -Name "Debugger" -Value "systray.exe" -PropertyType String -Force | Out-Null
    
    # Kill any currently running instances and child processes
    $ProcName = [System.IO.Path]::GetFileNameWithoutExtension($Exe)
    Get-Process -Name $ProcName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    & taskkill.exe /F /IM $Exe /T 2>&1 | Out-Null
}

# 3. Disable Activity History in Registry
$SystemPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $SystemPolicyPath)) {
    New-Item -Path $SystemPolicyPath -Force | Out-Null
}
New-ItemProperty -Path $SystemPolicyPath -Name "EnableActivityFeed" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $SystemPolicyPath -Name "PublishUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $SystemPolicyPath -Name "UploadUserActivities" -Value 0 -PropertyType DWord -Force | Out-Null

# 4. Disable Delivery Optimization (P2P Windows Updates)
$DoPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
if (-not (Test-Path $DoPath)) {
    New-Item -Path $DoPath -Force | Out-Null
}
New-ItemProperty -Path $DoPath -Name "DODownloadMode" -Value 0 -PropertyType DWord -Force | Out-Null

Write-Host "Done! All selected services, processes, and registry settings are now disabled." -ForegroundColor Green
Start-Sleep -Seconds 2
