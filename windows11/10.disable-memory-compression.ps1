## ONLY FOR SYSTEMS > 16GB RAM

#Requires -RunAsAdministrator

Write-Host "Disabling Windows Memory Compression..." -ForegroundColor Cyan

# Disable Memory Compression via MMAgent cmdlet
Disable-MMAgent -MemoryCompression

# Verify current MMAgent status
Get-MMAgent | Select-Object MemoryCompression

Write-Host "Memory Compression disabled. Please reboot your PC to apply changes." -ForegroundColor Green
