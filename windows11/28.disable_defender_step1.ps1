# Launch Windows Security -> Virus & threat protection settings via explorer.exe to bypass admin context restrictions
Start-Process "explorer.exe" -ArgumentList "windowsdefender://threatsettings"
