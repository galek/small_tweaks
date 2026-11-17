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

Write-Host "Applying optimization policies for Chrome and Edge..." -ForegroundColor Cyan

# 1. Google Chrome Policies
$chromePolicy = "HKLM:\SOFTWARE\Policies\Google\Chrome"
Set-RegistryValue -Path $chromePolicy -Name "BackgroundModeEnabled" -Value 0
Set-RegistryValue -Path $chromePolicy -Name "MetricsReportingEnabled" -Value 0
Set-RegistryValue -Path $chromePolicy -Name "PromotionalTabsEnabled" -Value 0
Set-RegistryValue -Path $chromePolicy -Name "NetworkPredictionOptions" -Value 2 # Disable page preloading

# 2. Microsoft Edge Policies
$edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Set-RegistryValue -Path $edgePolicy -Name "BackgroundModeEnabled" -Value 0
Set-RegistryValue -Path $edgePolicy -Name "StartupBoostEnabled" -Value 0
Set-RegistryValue -Path $edgePolicy -Name "HubsSidebarEnabled" -Value 0       # Disable Copilot/Sidebar
Set-RegistryValue -Path $edgePolicy -Name "EdgeShoppingAssistantEnabled" -Value 0
Set-RegistryValue -Path $edgePolicy -Name "DiagnosticData" -Value 0
Set-RegistryValue -Path $edgePolicy -Name "ShowRecommendationsEnabled" -Value 0

Write-Host "Browser optimization policies applied." -ForegroundColor Green
