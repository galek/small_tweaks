#Requires -RunAsAdministrator

Write-Host "Creating scheduled task for automatic Winget updates..." -ForegroundColor Cyan

$taskName = "WingetAutoUpdate"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Build the PowerShell command to update sources, upgrade all apps, and specifically check NVIDIA/AMD packages
$wingetCommand = @"
winget source update --disable-interactivity;
winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements;
winget upgrade --id Nvidia.NVIDIAApp --silent --accept-package-agreements --accept-source-agreements;
winget upgrade --id AMD.RyzenChipsetDriver --silent --accept-package-agreements --accept-source-agreements
"@ -replace "`r`n", " "

# Action: Run PowerShell hidden without flashing a console window
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$wingetCommand`""

# Trigger: Weekly on Sunday at 12:00 PM
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 12:00PM

# Principal: Run under the current logged-in user (required for Winget UWP context)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Settings: Run missed task as soon as possible, allow on battery, do not wake computer
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -MultipleInstances IgnoreNew

# Remove existing task with the same name if present
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Register the scheduled task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

Write-Host "Scheduled task '$taskName' created successfully (runs weekly on Sundays at 12:00 PM)." -ForegroundColor Green
