#Requires -RunAsAdministrator

Write-Host "Disabling Remote Assistance and Remote Registry..." -ForegroundColor Cyan

# Disable Remote Assistance invitations
$raPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
if (Test-Path $raPath) {
    Set-ItemProperty -Path $raPath -Name "fAllowToGetHelp" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $raPath -Name "fAllowFullControl" -Value 0 -Type DWord -Force
}

# Disable Remote Registry service
if (Get-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "RemoteRegistry" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "RemoteRegistry" -StartupType Disabled
}

Write-Host "Remote Assistance and Remote Registry disabled." -ForegroundColor Green
