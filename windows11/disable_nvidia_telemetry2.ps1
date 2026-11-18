# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Payload script to be encoded in Base64 and embedded directly into the Scheduled Task
$PayloadScript = @'
$NvBaseDir = "$env:ProgramFiles\NVIDIA Corporation"
$NeedRestart = $false

# Disable FrameView SDK Service if re-enabled by driver installer
$FvSvc = Get-Service -Name "FvSvc" -ErrorAction SilentlyContinue
if ($FvSvc -and ($FvSvc.StartType -ne 'Disabled' -or $FvSvc.Status -eq 'Running')) {
    Stop-Service -Name "FvSvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "FvSvc" -StartupType Disabled -ErrorAction SilentlyContinue
}

if (Test-Path $NvBaseDir) {
    $TelemetryFiles = Get-ChildItem -Path $NvBaseDir -Filter "*NvTelemetry*.dll" -Recurse -ErrorAction SilentlyContinue

    foreach ($File in $TelemetryFiles) {
        & icacls.exe "$($File.FullName)" /reset /Q | Out-Null
        Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        $File.Refresh()

        if ($File.Length -gt 0) {
            if (-not $NeedRestart) {
                Stop-Service -Name "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue
                $Procs = @("nvcontainer", "NVIDIA Overlay", "NVIDIA App", "nvsphelper64", "NVIDIA Web Helper", "NVIDIA Share")
                foreach ($P in $Procs) {
                    Get-Process -Name $P -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                    & taskkill.exe /F /IM "$P.exe" /T 2>&1 | Out-Null
                }
                Start-Sleep -Milliseconds 800
                $NeedRestart = $true
            }

            Remove-Item -Path $File.FullName -Force -ErrorAction SilentlyContinue
            New-Item -Path $File.FullName -ItemType File -Force | Out-Null
        }

        Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
        & icacls.exe "$($File.FullName)" /deny "*S-1-1-0:(W,D,WDAC,WO)" "*S-1-5-18:(W,D,WDAC,WO)" /Q | Out-Null
    }
}

if ($NeedRestart) {
    Start-Service -Name "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
}
'@

# Encode payload to UTF-16LE Base64 (required format for powershell.exe -EncodedCommand)
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($PayloadScript)
$EncodedCommand = [Convert]::ToBase64String($Bytes)

# Register or overwrite the self-contained Scheduled Task
$TaskName = "NeutralizeNvidiaTelemetry"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null

# Execute the task immediately to verify and apply locks right now
Start-ScheduledTask -TaskName $TaskName

Write-Host "Task '$TaskName' registered with embedded Base64 payload and executed." -ForegroundColor Green
Start-Sleep -Seconds 2
