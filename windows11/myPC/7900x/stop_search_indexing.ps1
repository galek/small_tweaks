# Stop the Windows Search service immediately
Stop-Service -Name "WSearch" -Force

# Disable the service permanently so it never starts again
Set-Service -Name "WSearch" -StartupType Disabled
