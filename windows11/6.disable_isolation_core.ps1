#Requires -RunAsAdministrator

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

Write-Host "Disabling Core Isolation (Memory Integrity / HVCI) and VBS..." -ForegroundColor Cyan

# 1. Disable Memory Integrity (Hypervisor-Enforced Code Integrity - HVCI)
$hvciPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
Set-RegistryValue -Path $hvciPath -Name "Enabled" -Value 0
Set-RegistryValue -Path $hvciPath -Name "WasEnabledBy" -Value 0

# 2. Disable Credential Guard and Virtualization-Based Security (VBS)
$deviceGuardPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
Set-RegistryValue -Path $deviceGuardPath -Name "EnableVirtualizationBasedSecurity" -Value 0
Set-RegistryValue -Path $deviceGuardPath -Name "RequirePlatformSecurityFeatures" -Value 0
Set-RegistryValue -Path $deviceGuardPath -Name "LsaCfgFlags" -Value 0

# 3. Disable Vulnerable Driver Blocklist (optional, prevents blocking legacy/custom drivers)
$ciConfigPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config"
Set-RegistryValue -Path $ciConfigPath -Name "VulnerableDriverBlocklistEnable" -Value 0

Write-Host "Core Isolation and VBS have been disabled. A system reboot is required to apply changes." -ForegroundColor Green
