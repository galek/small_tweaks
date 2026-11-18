# Ensure the script runs with Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Disabling Windows self-healing and telemetry rollback components..." -ForegroundColor Cyan

# 1. Disable PerformRemediation Scheduled Task
$TaskPath = "\Microsoft\Windows\WaaSMedic\"
$TaskName = "PerformRemediation"
$Task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Task) {
    Disable-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[OK] Scheduled Task '$TaskName' disabled." -ForegroundColor Green
}

# 2. Disable WaaSMedicSvc via Registry (taking ownership if protected by TrustedInstaller)
$SvcKeyPath = "SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
$FullRegPath = "HKLM:\$SvcKeyPath"

if (Test-Path $FullRegPath) {
    Stop-Service -Name "WaaSMedicSvc" -Force -ErrorAction SilentlyContinue

    try {
        # Try direct modification first
        Set-ItemProperty -Path $FullRegPath -Name "Start" -Value 4 -Type DWord -Force -ErrorAction Stop
    } catch {
        # Take ownership of the registry key for Administrators (*S-1-5-32-544) if access is denied
        $Def = @"
        using System;
        using System.Runtime.InteropServices;
        public class TokenManipulator {
            [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
            [DllImport("kernel32.dll", ExactSpelling = true)]
            internal static extern IntPtr GetCurrentProcess();
            [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
            [DllImport("advapi32.dll", SetLastError = true)]
            internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
            [StructLayout(LayoutKind.Sequential, Pack = 1)]
            internal struct TokPriv1Luid { public int Count; public long Luid; public int Attr; }
            public static void EnablePrivilege(string privilege) {
                IntPtr htok = IntPtr.Zero;
                OpenProcessToken(GetCurrentProcess(), 0x28, ref htok);
                TokPriv1Luid tp = new TokPriv1Luid { Count = 1, Attr = 0x2 };
                LookupPrivilegeValue(null, privilege, ref tp.Luid);
                AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            }
        }
"@
        Add-Type -TypeDefinition $Def -ErrorAction SilentlyContinue
        [TokenManipulator]::EnablePrivilege("SeTakeOwnershipPrivilege")

        $AdminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
        $RegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($SvcKeyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
        $Acl = $RegKey.GetAccessControl()
        $Acl.SetOwner($AdminSid)
        $RegKey.SetAccessControl($Acl)
        $RegKey.Close()

        # Grant FullControl to Administrators
        $RegKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($SvcKeyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
        $Acl = $RegKey.GetAccessControl()
        $Rule = New-Object System.Security.AccessControl.RegistryAccessRule($AdminSid, [System.Security.AccessControl.RegistryRights]::FullControl, [System.Security.AccessControl.InheritanceFlags]::ContainerInherit, [System.Security.AccessControl.PropagationFlags]::None, [System.Security.AccessControl.AccessControlType]::Allow)
        $Acl.SetAccessRule($Rule)
        $RegKey.SetAccessControl($Acl)
        $RegKey.Close()

        # Apply the Disabled start value now that permissions are granted
        Set-ItemProperty -Path $FullRegPath -Name "Start" -Value 4 -Type DWord -Force
    }

    # Disable service recovery/restart triggers
    New-ItemProperty -Path $FullRegPath -Name "FailureActionsOnNonCrashFailures" -Value 0 -PropertyType DWord -Force | Out-Null
    Write-Host "[OK] Service 'WaaSMedicSvc' set to Disabled (Start = 4)." -ForegroundColor Green
}

# 3. Block sedlauncher.exe (Windows Remediation Service executable) via IFEO
$SedIfEo = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sedlauncher.exe"
if (-not (Test-Path $SedIfEo)) {
    New-Item -Path $SedIfEo -Force | Out-Null
}
New-ItemProperty -Path $SedIfEo -Name "Debugger" -Value "systray.exe" -PropertyType String -Force | Out-Null
& taskkill.exe /F /IM "sedlauncher.exe" /T 2>&1 | Out-Null
Write-Host "[OK] Blocked 'sedlauncher.exe' via IFEO." -ForegroundColor Green

Write-Host "`nAll rollback/remediation mechanisms are now permanently disabled." -ForegroundColor Cyan
Start-Sleep -Seconds 2
