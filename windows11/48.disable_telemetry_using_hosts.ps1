# Self-elevate to Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupFile = "$hostsFile.bak"

# Create backup
Copy-Item -Path $hostsFile -Destination $backupFile -Force
Write-Host "Backup saved to: $backupFile" -ForegroundColor Cyan

# Domain parts array to prevent interface link-stripping
$domainParts = @(
    @("vortex", "data", "microsoft", "com"),
    @("vortex-win", "data", "microsoft", "com"),
    @("telecommand", "telemetry", "microsoft", "com"),
    @("oca", "telemetry", "microsoft", "com"),
    @("watson", "telemetry", "microsoft", "com"),
    @("umwatsonc", "events", "data", "microsoft", "com"),
    @("self", "events", "data", "microsoft", "com"),
    @("settings-win", "data", "microsoft", "com"),
    @("ceuswatcab01", "blob", "core", "windows", "net"),
    @("ceuswatcab02", "blob", "core", "windows", "net"),
    @("eaus2watcab01", "blob", "core", "windows", "net"),
    @("eaus2watcab02", "blob", "core", "windows", "net"),
    @("weus2watcab01", "blob", "core", "windows", "net"),
    @("weus2watcab02", "blob", "core", "windows", "net"),
    @("sqm", "telemetry", "microsoft", "com"),
    @("diagnostics", "support", "microsoft", "com"),
    @("ads", "msn", "com"),
    @("adnexus", "net"),
    @("c", "msn", "com"),
    @("arc", "msn", "com"),
    @("rad", "msn", "com"),
    @("events", "gfe", "nvidia", "com"),
    @("telemetry", "gfe", "nvidia", "com"),
    @("telemetry", "nvidia", "com"),
    @("gfwsl", "geforce", "com")
)

$existingText = Get-Content -Path $hostsFile -Raw -ErrorAction SilentlyContinue
if ($null -eq $existingText) { $existingText = "" }

$addedCount = 0
Add-Content -Path $hostsFile -Value "`r`n# --- Telemetry Blocklist ---" -Encoding ASCII

foreach ($parts in $domainParts) {
    $d = $parts -join "."
    if ($existingText -notlike "*$d*") {
        Add-Content -Path $hostsFile -Value "0.0.0.0 $d" -Encoding ASCII
        Write-Host "Blocked: $d" -ForegroundColor Green
        $addedCount++
    }
}

Write-Host "`nTotal added: $addedCount domains." -ForegroundColor Cyan

# Flush DNS cache
& ipconfig.exe /flushdns | Out-Null
Write-Host "DNS cache flushed." -ForegroundColor Cyan
Start-Sleep -Seconds 2
