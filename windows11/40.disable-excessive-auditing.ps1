#Requires -RunAsAdministrator

Write-Host "Disabling excessive Windows Security auditing subcategories..." -ForegroundColor Cyan

$subcategories = @(
    "Filtering Platform Packet Drop",
    "Filtering Platform Connection",
    "Process Creation",
    "Process Termination",
    "Handle Manipulation",
    "Registry",
    "File System"
)

foreach ($sub in $subcategories) {
    auditpol /set /subcategory:"$sub" /success:disable /failure:disable 2>$null | Out-Null
}

Write-Host "Excessive security auditing disabled." -ForegroundColor Green
