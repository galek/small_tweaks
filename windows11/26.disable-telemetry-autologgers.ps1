#Requires -RunAsAdministrator

# Helper function to take ownership and grant FullControl to Administrators on protected registry keys
function Enable-RegistryKeyAccess {
    param ([string]$SubKeyPath)
    
    # Enable SeTakeOwnershipPrivilege for the current PowerShell process
    $definition = @"
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
        public static void AddPrivilege(string privilege) {
            IntPtr htok = IntPtr.Zero;
            OpenProcessToken(GetCurrentProcess(), 0x28, ref htok);
            TokPriv1Luid tp = new TokPriv1Luid { Count = 1, Attr = 0x2 };
            LookupPrivilegeValue(null, privilege, ref tp.Luid);
            AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        }
    }
"@
    Add-Type -TypeDefinition $definition -ErrorAction SilentlyContinue
    [TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege")

    $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544") # Built-in Administrators
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($SubKeyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::TakeOwnership)
    $acl = $key.GetAccessControl()
    $acl.SetOwner($adminSid)
    $key.SetAccessControl($acl)
    $key.Close()

    # Grant FullControl to Administrators
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($SubKeyPath, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree, [System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($adminSid, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    $key.Close()
}

Write-Host "Disabling diagnostic ETW AutoLoggers..." -ForegroundColor Cyan

$autoLoggers = @(
    "CloudExperienceHostOobe",
    "DefenderApiLogger",
    "DefenderAuditLogger",
    "DiagLog",
    "ReadyBoot",
    "SqmLogger",
    "WdiContextLog",
    "WiFiSession"
)

$relativeBase = "SYSTEM\CurrentControlSet\Control\WMI\Autologger"

foreach ($logger in $autoLoggers) {
    $subKey = "$relativeBase\$logger"
    $fullPath = "HKLM:\$subKey"
    
    if (Test-Path $fullPath) {
        try {
            Set-ItemProperty -Path $fullPath -Name "Start" -Value 0 -Type DWord -Force -ErrorAction Stop
            Write-Host "Disabled AutoLogger: $logger" -ForegroundColor DarkGray
        }
        catch [System.UnauthorizedAccessException] {
            Write-Host "Taking ownership of protected key: $logger..." -ForegroundColor Yellow
            Enable-RegistryKeyAccess -SubKeyPath $subKey
            Set-ItemProperty -Path $fullPath -Name "Start" -Value 0 -Type DWord -Force
            Write-Host "Disabled AutoLogger: $logger" -ForegroundColor DarkGray
        }
    }
}

Write-Host "All diagnostic AutoLoggers disabled. Reboot to apply." -ForegroundColor Green
