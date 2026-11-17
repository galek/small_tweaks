Write-Host "Disabling Windows Auto HDR specifically for browsers and video players..." -ForegroundColor Cyan

$d3dBase = "HKCU:\Software\Microsoft\Direct3D"
if (-not (Test-Path $d3dBase)) {
    New-Item -Path $d3dBase -Force | Out-Null
}

# List of browser and media player executables to exclude from Windows Auto HDR
$videoApps = @(
    "chrome.exe",
    "msedge.exe",
    "firefox.exe",
    "brave.exe",
    "opera.exe",
    "yandex.exe",
    "vlc.exe",
    "mpc-hc64.exe",
    "mpc-be64.exe",
    "mpv.exe",
    "PotPlayerMini64.exe"
)

# Find existing ApplicationX subkeys to avoid overwriting them
$existingKeys = Get-ChildItem -Path $d3dBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^Application\d+$" }
$existingApps = @{}
$maxIndex = -1

foreach ($key in $existingKeys) {
    $index = [int]($key.PSChildName -replace "Application", "")
    if ($index -gt $maxIndex) { $maxIndex = $index }
    $name = (Get-ItemProperty -Path $key.PSPath -Name "Name" -ErrorAction SilentlyContinue).Name
    if ($name) {
        $existingApps[$name.ToLower()] = $key.PSPath
    }
}

foreach ($app in $videoApps) {
    $lowerApp = $app.ToLower()
    if ($existingApps.ContainsKey($lowerApp)) {
        $targetPath = $existingApps[$lowerApp]
    }
    else {
        $maxIndex++
        $targetPath = Join-Path $d3dBase "Application$maxIndex"
        New-Item -Path $targetPath -Force | Out-Null
        Set-ItemProperty -Path $targetPath -Name "Name" -Value $app -Type String -Force
    }
    
    # Disable Auto HDR for this specific executable (0 = Off)
    Set-ItemProperty -Path $targetPath -Name "AutoHDREnable" -Value 0 -Type DWord -Force
    Write-Host "Excluded from Auto HDR: $app" -ForegroundColor DarkGray
}

Write-Host "Auto HDR excluded for video apps. Restart your browser/player to apply." -ForegroundColor Green
