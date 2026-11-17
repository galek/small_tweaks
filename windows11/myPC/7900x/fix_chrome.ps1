# Close Chrome so it does not overwrite Local State on exit
Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$LocalStatePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"

if (Test-Path $LocalStatePath) {
    $Json = Get-Content -Path $LocalStatePath -Raw -Encoding UTF8 | ConvertFrom-Json

    # Ensure browser and enabled_labs_experiments nodes exist
    if (-not $Json.PSObject.Properties["browser"]) {
        $Json | Add-Member -MemberType NoteProperty -Name "browser" -Value ([PSCustomObject]@{})
    }
    if (-not $Json.browser.PSObject.Properties["enabled_labs_experiments"]) {
        $Json.browser | Add-Member -MemberType NoteProperty -Name "enabled_labs_experiments" -Value @()
    }

    # Target flags from the screenshot (@1 = Enabled, @2 = Disabled)
    $TargetFlags = @{
        "enable-rusty-ico"                 = "enable-rusty-ico@1"
        "enable-rusty-jpeg"                = "enable-rusty-jpeg@1"
        "enable-quic"                      = "enable-quic@1"
        "enable-gpu-rasterization"         = "enable-gpu-rasterization@1"
        "in-product-help-demo-mode-choice" = "in-product-help-demo-mode-choice@2"
        "enable-delegated-compositing"     = "enable-delegated-compositing@1"
    }

    # Keep existing flags that are not in our target list
    $CurrentFlags = @($Json.browser.enabled_labs_experiments)
    $UpdatedFlags = [System.Collections.Generic.List[string]]::new()

    foreach ($Item in $CurrentFlags) {
        $FlagName = ($Item -split "@")[0]
        if (-not $TargetFlags.ContainsKey($FlagName)) {
            $UpdatedFlags.Add($Item)
        }
    }

    # Add our target flags with required values
    foreach ($Value in $TargetFlags.Values) {
        $UpdatedFlags.Add($Value)
    }

    $Json.browser.enabled_labs_experiments = $UpdatedFlags.ToArray()

    # Save back to Local State without BOM
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($LocalStatePath, ($Json | ConvertTo-Json -Depth 100 -Compress), $Utf8NoBom)

    Write-Host "Флаги успешно записаны в Local State." -ForegroundColor Green
} else {
    Write-Warning "Файл Local State не найден по пути: $LocalStatePath"
}

# Start Chrome back
Start-Process "chrome.exe"
