#Requires -RunAsAdministrator

$featuresPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
$tamperValue = (Get-ItemProperty -Path $featuresPath -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection

# Value 5 means Tamper Protection is currently ON
if ($tamperValue -eq 5) {
    Write-Host "Tamper Protection is currently ENABLED." -ForegroundColor Yellow
    Write-Host "Opening Windows Security settings... Please turn OFF 'Tamper Protection' manually." -ForegroundColor Cyan
    
    # Open Windows Security -> Virus & threat protection settings directly
    Start-Process "windowsdefender://threatsettings"
    
    # Wait loop until the user toggles Tamper Protection off (value changes from 5)
    while ((Get-ItemProperty -Path $featuresPath -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection -eq 5) {
        Start-Sleep -Seconds 2
    }
    
    Write-Host "Tamper Protection is now OFF. Continuing script..." -ForegroundColor Green
}
