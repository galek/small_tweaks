#!/bin/bash
# Run this script as root (with sudo)
# Usage:
#   sudo ./clean_logs.sh                - run log cleanup now
#   sudo ./clean_logs.sh --install-cron - install script and add to root's cron (weekly)

if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script as root (use sudo)." >&2
    exit 1
fi

# Install script to /usr/local/sbin and add to root's crontab
install_cron() {
    local TARGET_PATH="/usr/local/sbin/clean_logs.sh"
    local CRON_SCHEDULE="0 3 * * 0" # Every Sunday at 03:00
    local CRON_JOB="$CRON_SCHEDULE $TARGET_PATH >/dev/null 2>&1"

    # Copy script to system directory if executed from elsewhere
    if [ "$(realpath "$0")" != "$TARGET_PATH" ]; then
        cp "$0" "$TARGET_PATH"
        chmod 700 "$TARGET_PATH"
        echo "Script installed to $TARGET_PATH"
    fi

    # Check if the job already exists in crontab to prevent duplicates
    if crontab -l 2>/dev/null | grep -qF "$TARGET_PATH"; then
        echo "Cron job already exists."
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "Cron job added: $CRON_JOB"
    fi
    exit 0
}

# Set up cron schedule and exit if --install-cron argument is passed
if [ "$1" = "--install-cron" ]; then
    install_cron
fi

# Measure used disk space on root partition (in KB) before cleanup
USED_BEFORE=$(df -k / | awk 'NR==2 {print $3}')
FREE_BEFORE_H=$(df -h / | awk 'NR==2 {print $4}')

echo "Starting log cleanup... (Free space before: $FREE_BEFORE_H)"

# 1. Vacuum systemd journal logs (keep last 3 days or max 100 MB)
if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-time=3d
    journalctl --vacuum-size=100M
fi

# 2. Remove old archived and rotated logs in /var/log
find /var/log -type f \( -name "*.gz" -o -name "*.xz" -o -name "*.1" -o -name "*.old" \) -delete

# 3. Truncate active log files to 0 bytes without breaking running services
find /var/log -type f \( -name "*.log" -o -name "syslog" -o -name "messages" -o -name "auth.log" -o -name "kern.log" \) -exec truncate -s 0 {} +

# 4. Clean apt package manager cache (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
    apt-get clean
fi

# Measure used disk space after cleanup and calculate the difference
USED_AFTER=$(df -k / | awk 'NR==2 {print $3}')
FREE_AFTER_H=$(df -h / | awk 'NR==2 {print $4}')

FREED_KB=$((USED_BEFORE - USED_AFTER))
if [ "$FREED_KB" -lt 0 ]; then
    FREED_KB=0
fi

# Convert KB to human-readable format (MB or GB)
FREED_HUMAN=$(awk -v kb="$FREED_KB" 'BEGIN {
    if (kb >= 1048576) printf "%.2f GB", kb/1048576;
    else printf "%.2f MB", kb/1024;
}')

echo "----------------------------------------"
echo "Log cleanup completed!"
echo "Freed space:      $FREED_HUMAN"
echo "Free space after: $FREE_AFTER_H"
