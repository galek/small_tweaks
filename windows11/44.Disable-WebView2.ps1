# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$TargetExe = "msedgewebview2.exe"
$ProcessName = "msedgewebview2"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$TargetExe"

# Create the registry key if it does not exist
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Set the Debugger value to block execution
New-ItemProperty -Path $RegPath -Name "Debugger" -Value "systray.exe" -PropertyType String -Force | Out-Null

# Forcefully terminate all running instances via PowerShell
Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Ensure all child processes and trees are killed via taskkill
& taskkill.exe /F /IM $TargetExe /T 2>&1 | Out-Null

Write-Host "$TargetExe has been blocked and all running processes terminated." -ForegroundColor Green
Start-Sleep -Seconds 2
