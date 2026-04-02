#!/bin/bash

# --- Advanced System Maintenance for Soul ---
# System:  OS: Arch-Hyprland | FS: Btrfs
# Purpose: Full system health check, maintenance, and logging.
# this script performs battery health checks, Btrfs maintenance, system upgrades, cleanup, and hardware error audits, while logging all actions for future reference.

# 1. SETUP LOGGING
LOG_DIR="$HOME/2_Resources/97_Logs/Arch"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log_$(date +'%Y-%m-%d_%H-%M').txt"

# Function to log and print simultaneously
log_info() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

exec > >(tee -a "$LOG_FILE") 2>&1

log_info "--- ARCH MAINTENANCE SESSION: $(date) ---"

# 2. BATTERY HEALTH (Lenovo Specific)
log_info "\n### [1/5] BATTERY HEALTH CHECK"
if [ -d "/sys/class/power_supply/BAT0" ]; then
    ENERGY_FULL=$(cat /sys/class/power_supply/BAT0/energy_full)
    ENERGY_DESIGN=$(cat /sys/class/power_supply/BAT0/energy_full_design)
    # Calculate health percentage using bc for float math
    HEALTH=$(echo "scale=2; ($ENERGY_FULL / $ENERGY_DESIGN) * 100" | bc)
    log_info "Battery Health: $HEALTH%"
    log_info "Cycle Count: $(cat /sys/class/power_supply/BAT0/cycle_count)"
else
    log_info "Battery information not found."
fi

# 3. BTRFS CARE (Scrub & Balance)
log_info "\n### [2/5] BTRFS FILE SYSTEM CARE"
log_info ">> Starting Btrfs scrub on / (checks for data corruption)..."
sudo btrfs scrub start -B /
log_info ">> Performing a limited balance (cleans up unused chunks)..."
sudo btrfs balance start -dusage=50 -musage=50 /

# 4. SYSTEM UPGRADE & SNAPSHOT
log_info "\n### [3/5] SYSTEM UPGRADE"
# Taking a manual snapshot before upgrade (assuming Snapper or Timeshift-autosnap)
if command -v snapper &> /dev/null; then
    log_info ">> Creating pre-upgrade Snapper snapshot..."
    sudo snapper create --description "Pre-Maintenance $(date)"
fi

log_info ">> Running Full System Upgrade..."
sudo pacman -Syu --noconfirm

# 5. CLEANUP & ORPHANS
log_info "\n### [4/5] DISK CLEANUP"
log_info ">> Clearing Pacman cache (keeping last 2 versions)..."
sudo paccache -rk2
log_info ">> Removing orphaned packages..."
orphans=$(pacman -Qtdq)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
else
    log_info "No orphans found."
fi

# 6. HARDWARE ERROR CHECK
log_info "\n### [5/5] HARDWARE LOG AUDIT"
log_info ">> Checking for kernel 'Hardware Error' or 'Critical' logs..."
journalctl -p 0..3 -b | tail -n 10
log_info ">> Checking for failed systemd units..."
systemctl --failed --no-legend

log_info "\n--- SESSION COMPLETE ---"
log_info "Log saved to: $LOG_FILE"
