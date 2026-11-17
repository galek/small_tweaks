#Requires -RunAsAdministrator

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

Write-Host "Disabling Windows Defender policies, services, and kernel drivers..." -ForegroundColor Cyan

# 1. Disable real-time, behavior, script, and cloud protection via Defender cmdlets
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue

# 2. Enforce permanent disable via Group Policy registry keys
$defenderPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
Set-RegistryValue -Path $defenderPolicy -Name "DisableAntiSpyware" -Value 1
Set-RegistryValue -Path $defenderPolicy -Name "DisableAntiVirus" -Value 1
Set-RegistryValue -Path $defenderPolicy -Name "ServiceKeepAlive" -Value 0

$rtPolicy = "$defenderPolicy\Real-Time Protection"
Set-RegistryValue -Path $rtPolicy -Name "DisableBehaviorMonitoring" -Value 1
Set-RegistryValue -Path $rtPolicy -Name "DisableOnAccessProtection" -Value 1
Set-RegistryValue -Path $rtPolicy -Name "DisableScanOnRealtimeEnable" -Value 1
Set-RegistryValue -Path $rtPolicy -Name "DisableIOAVProtection" -Value 1

# 3. Disable SmartScreen and Security Center notifications
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableNotifications" -Value 1

# 4. Disable core Defender services and kernel drivers (4 = Disabled)
$services = @("WinDefend", "WdNisSvc", "WdNisDrv", "WdFilter", "WdBoot", "Sense")
foreach ($svc in $services) {
    $svcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
    if (Test-Path $svcPath) {
        try {
            Set-ItemProperty -Path $svcPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction Stop
            Write-Host "Disabled service/driver: $svc" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "Failed to disable $svc (check if Tamper Protection is turned OFF)" -ForegroundColor Red
        }
    }
}

Write-Host "Windows Defender disabled. Reboot your PC now to unload WdFilter driver." -ForegroundColor Green
