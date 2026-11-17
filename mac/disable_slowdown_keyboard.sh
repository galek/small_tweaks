#!/bin/bash

# Check that the script is not run directly with sudo, otherwise defaults will apply to root instead of the current user
if [ "$EUID" -eq 0 ]; then
  echo "Please run this script as a regular user without sudo. It will ask for your password when needed."
  exit 1
fi

echo "Applying keyboard and input optimizations..."

# Disable floating language indicator near cursor
# Rollback: defaults delete kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled
defaults write kCFPreferencesAnyApplication TSMLanguageIndicatorEnabled -int 0

# Disable Quick Note hotkey (ID 190) and apply settings
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 190 "<dict><key>enabled</key><false/></dict>"
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Speed up key repeat rate and reduce initial delay
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# Set Fn/Globe key strictly to change input source
defaults write com.apple.HIToolbox AppleFnUsageType -int 1

# Disable accent press-and-hold popup menu
defaults write -g ApplePressAndHoldEnabled -bool false

# Disable per-window input source memory
defaults write com.apple.HIToolbox AppleGlobalTextInputProperties -dict TextInputGlobalPropertyPerContextInput 0

# Speed up window resize animations and tooltip delays
defaults write -g NSWindowResizeTime -float 0.001
defaults write -g NSInitialToolTipDelay -int 0

# Disable inline predictive text
defaults write -g NSAutomaticInlinePredictionEnabled -bool false

# Hide input menu icon from the Menu Bar and restart SystemUIServer
defaults write com.apple.TextInputMenu visible -bool false
killall SystemUIServer 2>/dev/null

# Request admin privileges to clear global HIToolbox cache
echo "Administrator password is required to clear the global keyboard cache:"
sudo rm -f /Library/Preferences/com.apple.HIToolbox.plist

# Restart text input background agents (ignore errors if not running)
killall -9 TextInputSwitcher TextInputMenuAgent 2>/dev/null

echo "Settings applied successfully."

# Prompt for safe reboot via macOS system event
read -p "A reboot is required to apply all changes. Reboot now? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    osascript -e 'tell app "System Events" to restart'
else
    echo "Please reboot your Mac manually later."
fi
