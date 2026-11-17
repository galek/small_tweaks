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

Write-Host "Disabling OneDrive integration via Group Policy..." -ForegroundColor Cyan

# Stop running OneDrive process if active
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue

# Prevent usage of OneDrive for file storage
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1

# Hide OneDrive from File Explorer navigation pane
Set-RegistryValue -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0

Write-Host "OneDrive disabled and hidden from File Explorer." -ForegroundColor Green
