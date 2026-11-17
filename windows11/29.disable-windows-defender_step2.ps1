#shutdown /r /o /f /t 0

reg load HKLM\OFFLINE C:\Windows\System32\config\SYSTEM
reg add "HKLM\OFFLINE\ControlSet001\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OFFLINE\ControlSet001\Services\WdNisSvc" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OFFLINE\ControlSet001\Services\WdNisDrv" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OFFLINE\ControlSet001\Services\WdFilter" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\OFFLINE\ControlSet001\Services\WdBoot" /v Start /t REG_DWORD /d 4 /f
reg unload HKLM\OFFLINE
wpeutil reboot
