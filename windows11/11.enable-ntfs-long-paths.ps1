#Requires -RunAsAdministrator

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

# Enable Win32 long paths (> 260 characters) in NTFS
Set-ItemProperty -Path $path -Name "LongPathsEnabled" -Value 1 -Type DWord -Force

Write-Host "NTFS Long Paths enabled successfully. A system reboot is recommended." -ForegroundColor Green
