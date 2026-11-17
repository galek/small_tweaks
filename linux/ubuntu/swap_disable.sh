#!/bin/bash
# Run this script as root (with sudo)
# Permanently disables swap and zram for Kubernetes/k3s nodes

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root (use sudo)." >&2
    exit 1
fi

echo "Disabling active swap..."
swapoff -a

# Comment out active swap entries in /etc/fstab without duplicating '#'
if grep -qE '^[^#]*\bswap\b' /etc/fstab; then
    cp /etc/fstab "/etc/fstab.bak.$(date +%F_%H-%M-%S)"
    sed -i -E '/^[^#]*\bswap\b/s/^/#/' /etc/fstab
    echo "Swap entries commented out in /etc/fstab."
fi

# Mask systemd swap units if any exist
SWAP_UNITS=$(systemctl list-units --type=swap --no-legend | awk '{print $1}')
if [ -n "$SWAP_UNITS" ]; then
    systemctl mask --now $SWAP_UNITS
    echo "Masked systemd swap units: $SWAP_UNITS"
fi

# Disable zram generator if installed (common in modern Ubuntu/Debian)
if systemctl list-unit-files | grep -q 'systemd-zram-setup'; then
    systemctl stop 'systemd-zram-setup@*' 2>/dev/null || true
    systemctl mask systemd-zram-setup@.service 2>/dev/null || true
    echo "Disabled systemd zram setup."
fi

# Remove common swap files if they exist
for f in /swap.img /swapfile; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo "Removed swap file: $f"
    fi
done

echo "----------------------------------------"
echo "Swap status verification:"
free -h

if [ -z "$(swapon --show)" ]; then
    echo "Success: Swap is completely disabled."
else
    echo "Warning: Some swap devices are still active:" >&2
    swapon --show >&2
    exit 1
fi
