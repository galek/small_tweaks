# Update winget sources first
winget source update

# List of essential applications (Package IDs)
$apps = @(
    "7zip.7zip",                        # 7-Zip archiver
    "Google.Chrome",                    # Google Chrome browser
    "VideoLAN.VLC",                     # VLC Media Player (includes codecs)
    "Microsoft.VisualStudioCode",       # VS Code
    "Git.Git",                          # Git version control
    "Fork.Fork",                        # Fork Git GUI
    "Microsoft.PowerToys",              # Windows PowerToys utilities
    "Telegram.TelegramDesktop",         # Telegram
    "Notepad++.Notepad++"               # Notepad++ text editor
)

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Cyan
    winget install --id $app --exact --silent --accept-package-agreements --accept-source-agreements
}

Write-Host "All applications installed successfully." -ForegroundColor Green
