# 1. Текст самого скрипта обновления
$ScriptBlock = {
    # Базовое ПО через Winget (Telegram, Steam, Thunderbird, VS Code, OpenIDE)
    $WingetApps = @(
        "Telegram.TelegramDesktop",
        "Valve.Steam",
        "Mozilla.Thunderbird",
        "Microsoft.VisualStudioCode",
        "OpenIDE.OpenIDE"
    )
    foreach ($App in $WingetApps) {
        winget upgrade --id $App --silent --accept-package-agreements --accept-source-agreements | Out-Null
    }

    # Visual Studio
    $VSInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe"
    if (Test-Path $VSInstaller) {
        Start-Process -FilePath $VSInstaller -ArgumentList "update --quiet --norestart" -Wait
    }

    # Расширения Visual Studio Code
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code --update-extensions | Out-Null
    }

    # Драйверы NVIDIA и AMD (через Windows Update)
    if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
        Get-WindowsUpdate -Category "Drivers" -Install -AcceptAll -IgnoreReboot | Out-Null
    }
}

# 2. Кодирование скрипта в Base64 для хранения внутри задачи
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($ScriptBlock.ToString())
$EncodedCommand = [Convert]::ToBase64String($Bytes)

# 3. Создание и регистрация задачи в Планировщике заданий
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $EncodedCommand"
$Trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName "AutoUpdateAllSoftware" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
