# Проверка прав администратора и автоматический перезапуск с повышением прав
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$TargetExe = "msedgewebview2.exe"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$TargetExe"

# Создание раздела в реестре, если его нет
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

# Установка заглушки Debugger
New-ItemProperty -Path $RegPath -Name "Debugger" -Value "systray.exe" -PropertyType String -Force | Out-Null

# Принудительное завершение уже запущенных процессов
Stop-Process -Name "msedgewebview2" -Force -ErrorAction SilentlyContinue

Write-Host "Запуск $TargetExe успешно заблокирован." -ForegroundColor Green
Start-Sleep -Seconds 2
