# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$NvBaseDir = "$env:ProgramFiles\NVIDIA Corporation"
$TaskName = "NeutralizeNvidiaTelemetry"
$NeedRestart = $false

if (Test-Path $NvBaseDir) {
    # Find all NvTelemetry*.dll files (including 0-byte stubs to verify their locks)
    $TelemetryFiles = Get-ChildItem -Path $NvBaseDir -Filter "*NvTelemetry*.dll" -Recurse -ErrorAction SilentlyContinue

    foreach ($File in $TelemetryFiles) {
        # Check if file is larger than 0 bytes (meaning a real DLL was installed/restored)
        if ($File.Length -gt 0) {
            if (-not $NeedRestart) {
                Stop-Service -Name "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue
                $NeedRestart = $true
            }

            # Remove Read-Only attribute and reset ACLs so we can replace the file
            Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            & icacls.exe "$($File.FullName)" /reset /Q | Out-Null
            Remove-Item -Path $File.FullName -Force -ErrorAction SilentlyContinue

            # Create an empty 0-byte dummy file
            New-Item -Path $File.FullName -ItemType File -Force | Out-Null
            Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue

            # Lock the dummy file with Deny Write/Delete permissions for Everyone and SYSTEM
            & icacls.exe "$($File.FullName)" /deny "Everyone:(W,D,WDAC,WO)" "SYSTEM:(W,D,WDAC,WO)" /Q | Out-Null
            Write-Host "Replaced and locked with ACL: $($File.FullName)" -ForegroundColor Green
        }
    }
}

# Restart NVIDIA Display Container only if real DLLs were replaced
if ($NeedRestart) {
    Start-Service -Name "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
}

# Register a Scheduled Task to run this exact script at every system startup
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $ExistingTask) {
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings | Out-Null
    Write-Host "Scheduled Task '$TaskName' registered to run at startup." -ForegroundColor Cyan
}

Start-Sleep -Seconds 2
