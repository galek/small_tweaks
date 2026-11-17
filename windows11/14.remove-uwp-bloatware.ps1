#Requires -RunAsAdministrator

Write-Host "Removing pre-installed UWP bloatware apps..." -ForegroundColor Cyan

# List of Appx package patterns to remove
$bloatwareList = @(
    "Clipchamp.Clipchamp",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
#    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
#    "Microsoft.WindowsSoundRecorder",
#    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftCorporationII.QuickAssist"
)

foreach ($app in $bloatwareList) {
    # Remove for current user
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    
    # Remove provisioned package so it won't install for new users
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*$app*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    
    Write-Host "Processed: $app" -ForegroundColor DarkGray
}

Write-Host "UWP bloatware removal completed." -ForegroundColor Green
