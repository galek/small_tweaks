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

Write-Host "Applying selected debloat, service, and UI performance tweaks..." -ForegroundColor Cyan

# ==============================================================================
# 1. COPILOT, WINDOWS AI & BACKGROUND UWP APPS
# ==============================================================================
# Disable Windows Copilot and Windows AI Recall
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1

# Disable UWP background apps globally
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2

# ==============================================================================
# 2. SEARCH INDEXING (FILE NAMES ONLY, NO FILE CONTENTS)
# ==============================================================================
# Disable indexing of file contents (keeps fast file name search intact)
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowIndexingEncryptedStoresOrItems" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "PreventIndexingUncachedContent" -Value 1

# Disable web search integration in Start Menu search
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0

# ==============================================================================
# 3. TELEMETRY & COMPATIBILITY SERVICES
# ==============================================================================
# Disable Diagnostic Data collection via policy
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Disable Telemetry (DiagTrack), WAP Push, and Program Compatibility Assistant (PcaSvc)
$servicesToDisable = @("DiagTrack", "dmwappushservice", "PcaSvc")
foreach ($svc in $servicesToDisable) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled
    }
}

# ==============================================================================
# 4. XBOX GAME BAR & GAME DVR
# ==============================================================================
Set-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0

# ==============================================================================
# 5. TRANSPARENCY & UI ANIMATIONS
# ==============================================================================
# Disable transparency effects (Acrylic / Mica)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0

# Disable window minimize/maximize animations and taskbar animations
Set-RegistryValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0

# Set Visual Effects to custom/performance mode (disables fade, slide, shadow animations)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3
$userPrefMask = [byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value $userPrefMask -Type Binary -Force

Write-Host "Restarting File Explorer to apply UI changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force

Write-Host "All requested features and services have been configured. Reboot to finalize service states." -ForegroundColor Green
