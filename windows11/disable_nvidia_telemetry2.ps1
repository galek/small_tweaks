# Check for Administrator privileges and self-elevate if necessary
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$NvBaseDir = "$env:ProgramFiles\NVIDIA Corporation"
$TaskName = "NeutralizeNvidiaTelemetry"
$NeedRestart = $false

# Helper function to forcefully kill all NVIDIA processes holding DLL locks
function Stop-AllNvidiaProcesses {
    Stop-Service -Name "NVDisplay.ContainerLocalSystem" -Force -ErrorAction SilentlyContinue
    Stop-Service -Name "FvSvc" -Force -ErrorAction SilentlyContinue
    
    $NvProcs = @("nvcontainer", "NVIDIA Overlay", "NVIDIA App", "nvsphelper64", "NVIDIA Web Helper", "NVIDIA Share")
    foreach ($Proc in $NvProcs) {
        Get-Process -Name $Proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        & taskkill.exe /F /IM "$Proc.exe" /T 2>&1 | Out-Null
    }
    Start-Sleep -Milliseconds 800
}

if (Test-Path $NvBaseDir) {
    $TelemetryFiles = Get-ChildItem -Path $NvBaseDir -Filter "*NvTelemetry*.dll" -Recurse -ErrorAction SilentlyContinue

    foreach ($File in $TelemetryFiles) {
        # Reset existing ACLs and Read-Only attribute first in case a previous run locked the real file
        & icacls.exe "$($File.FullName)" /reset /Q | Out-Null
        Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue

        # Refresh file info to check actual size
        $File.Refresh()

        if ($File.Length -gt 0) {
            if (-not $NeedRestart) {
                Stop-AllNvidiaProcesses
                $NeedRestart = $true
            }

            # Remove original DLL
            Remove-Item -Path $File.FullName -Force -ErrorAction SilentlyContinue

            # Create an empty 0-byte dummy file
            New-Item -Path $File.FullName -ItemType File -Force | Out-Null
            Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue

            # Lock using language-independent SIDs: *S-1-1-0 (Everyone) and *S-1-5-18 (SYSTEM)
            & icacls.exe "$($File.FullName)" /deny "*S-1-1-0:(W,D,WDAC,WO)" "*S-1-5-18:(W,D,WDAC,WO)" /Q | Out-Null
            Write-Host "Neutralized and locked (0 bytes): $($File.FullName)" -ForegroundColor Green
        } else {
            # Re-apply ACL lock on existing 0-byte stub
            Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
            & icacls.exe "$($File.FullName)" /deny "*S-1-1-0:(W,D,WDAC,WO)" "*S-1-5-18:(W,D,WDAC,WO)" /Q | Out-Null
            Write-Host "Verified 0-byte stub lock: $($File.FullName)" -ForegroundColor Gray
        }
    }
}

# Restart core NVIDIA Display Container if processes were stopped
if ($NeedRestart) {
    Start-Service -Name "NVDisplay.ContainerLocalSystem" -ErrorAction SilentlyContinue
}

# Register or update the Scheduled Task with the current script path
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
Write-Host "Scheduled Task '$TaskName' updated to run from: $PSCommandPath" -ForegroundColor Cyan

Start-Sleep -Seconds 2
