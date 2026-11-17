#Requires -RunAsAdministrator

# Helper function to safely set registry values
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

Write-Host "Applying Windows 11 26H2 configuration tweaks..." -ForegroundColor Cyan

# ==============================================================================
# 1. FILE EXPLORER & UI TWEAKS
# ==============================================================================
# Show file extensions (0 = Show, 1 = Hide)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# Show hidden files and folders (1 = Show, 2 = Hide)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Restore classic Windows 10 right-click context menu
$contextMenuPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (-not (Test-Path $contextMenuPath)) {
    New-Item -Path $contextMenuPath -Force | Out-Null
}
Set-ItemProperty -Path $contextMenuPath -Name "(Default)" -Value "" -Type String -Force

# Enable "End Task" option on taskbar right-click menu
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1

# ==============================================================================
# 2. PERFORMANCE, POWER & INPUT
# ==============================================================================
# Disable UWP background apps globally
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2

# Disable EcoQoS (Efficiency Mode throttling) system-wide
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1

# Disable Hibernation and Fast Startup (removes hiberfil.sys)
powercfg -h off
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0

# Disable Sticky Keys prompt (5x Shift)
Set-RegistryValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Type String

# ==============================================================================
# 3. WINDOWS UPDATE & NETWORK
# ==============================================================================
# Disable Delivery Optimization P2P sharing (0 = Off / HTTP only)
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0

# Disable automatic reboot after Windows Updates when users are logged on
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1

# ==============================================================================
# 4. APPLY CHANGES
# ==============================================================================
Write-Host "Restarting File Explorer to apply UI changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force

Write-Host "All tweaks applied successfully. A full reboot is recommended for kernel/policy changes." -ForegroundColor Green
