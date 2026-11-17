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

Write-Host "Disabling Cortana, Bing web search, and Search Highlights in Start Menu..." -ForegroundColor Cyan

# 1. Disable Cortana via Group Policy
$cortanaPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
Set-RegistryValue -Path $cortanaPolicy -Name "AllowCortana" -Value 0
Set-RegistryValue -Path $cortanaPolicy -Name "AllowCortanaAboveLock" -Value 0
Set-RegistryValue -Path $cortanaPolicy -Name "AllowSearchToUseLocation" -Value 0
Set-RegistryValue -Path $cortanaPolicy -Name "ConnectedSearchUseWeb" -Value 0
Set-RegistryValue -Path $cortanaPolicy -Name "DisableWebSearch" -Value 1

# 2. Disable Bing search and web suggestions in Start Menu (Current User)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1

# 3. Disable Search Highlights (daily icons/banners in Search box)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDynamicSearchBoxEnabled" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -Value 0

# 4. Disable cloud content search (OneDrive/Microsoft account results in Start)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsMSACloudSearchEnabled" -Value 0
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsAADCloudSearchEnabled" -Value 0

Write-Host "Restarting File Explorer to apply Start Menu search changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force

Write-Host "Start Menu web search and Cortana disabled successfully." -ForegroundColor Green
