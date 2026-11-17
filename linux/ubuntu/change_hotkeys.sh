#!/bin/bash
# Run this script as a regular user, not as root
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root (without sudo)!" >&2
    echo "The script will prompt for your sudo password when installing packages." >&2
    exit 1
fi


sudo apt install -y gnome-tweaks

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    # Ubuntu 26 way - if you use wayland
    gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"
else
    # Ubuntu 22 way - x11
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Shift>Alt_L', '<Super>Space']"
fi

killall firefox 2>/dev/null

PREF='user_pref("ui.key.menuAccessKeyFocuses", false);'
for d in ~/.mozilla/firefox/*.default* ~/snap/firefox/common/.mozilla/firefox/*.default*; do
    [ -d "$d" ] && (grep -qxF "$PREF" "$d/user.js" 2>/dev/null || echo "$PREF" >> "$d/user.js") && echo "Готово: $d/user.js"
done
