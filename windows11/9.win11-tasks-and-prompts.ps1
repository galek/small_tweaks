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

Write-Host "Configuring scheduled tasks, session restore, and system prompts..." -ForegroundColor Cyan

# 1. Disable telemetry and diagnostic scheduled tasks
$scheduledTasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\Autochk\Proxy"
)

foreach ($task in $scheduledTasks) {
    $taskPath = Split-Path -Path $task -Parent
    $taskName = Split-Path -Path $task -Leaf
    if (Get-ScheduledTask -TaskPath "$taskPath\" -TaskName $taskName -ErrorAction SilentlyContinue) {
        Disable-ScheduledTask -TaskPath "$taskPath\" -TaskName $taskName | Out-Null
        Write-Host "Disabled task: $taskName" -ForegroundColor DarkGray
    }
}

# 2. Disable automatic restoration of open folders and apps after reboot
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "PersistBrowsers" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "RestartApps" -Value 0

# 3. Disable "Finish setting up your device" (SCOOBE) and Windows Welcome Experience prompts
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" -Name "ScoobeSystemSettingEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Value 0

Write-Host "Tasks and prompt settings applied successfully." -ForegroundColor Green
