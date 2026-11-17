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

Write-Host "Optimizing File Explorer folder discovery and network scanning..." -ForegroundColor Cyan

# Disable automatic folder type discovery (prevents Explorer slowdowns on large folders)
$shellBags = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
Set-RegistryValue -Path $shellBags -Name "FolderType" -Value "NotSpecified" -Type String

# Disable automatic discovery of network folders and printers
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "NoNetCrawling" -Value 1

# Open File Explorer directly to "This PC" instead of "Home" (1 = This PC, 2 = Home)
Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1

Write-Host "Restarting File Explorer to apply changes..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force

Write-Host "File Explorer speed optimizations applied." -ForegroundColor Green
