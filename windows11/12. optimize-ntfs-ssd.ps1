#Requires -RunAsAdministrator

Write-Host "Optimizing NTFS settings for SSD..." -ForegroundColor Cyan

# Disable NTFS Last Access Timestamp updates (1 = Disabled)
fsutil behavior set disablelastaccess 1 | Out-Null

# Disable legacy 8.3 short file name creation (1 = Disabled on all volumes)
fsutil behavior set disable8dot3 1 | Out-Null

Write-Host "NTFS SSD optimizations applied successfully." -ForegroundColor Green
