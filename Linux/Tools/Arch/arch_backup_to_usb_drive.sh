#!/usr/bin/env bash
# Weekly Incremental Backup for Soul
# Lenovo Ideapad Slim 3 | Arch-Hyprland (jakoolit)

set -e

# Configuration
USB_LABEL="ARCH_BACKUP"
MOUNT_POINT="/mnt/usb_backup"
SNAP_DIR="/.snapshots"
DATE_STAMP=$(date +%Y-%m-%d)
NEW_SNAP_NAME="root_backup_${DATE_STAMP}"
NEW_SNAP_PATH="${SNAP_DIR}/${NEW_SNAP_NAME}"
LATEST_LINK="${MOUNT_POINT}/latest_root"

# 1. Root and USB Checks
[ "$EUID" -ne 0 ] && echo "❌ Run as sudo" && exit 1
blkid -L "$USB_LABEL" > /dev/null || (echo "❌ Plug in USB: $USB_LABEL" && exit 1)

# 2. Mount USB
mkdir -p "$MOUNT_POINT"
mountpoint -q "$MOUNT_POINT" || mount -o compress=zstd "LABEL=$USB_LABEL" "$MOUNT_POINT"

# 3. Create New Snapshot at /.snapshots
echo "📸 Creating snapshot: ${NEW_SNAP_NAME}"
if [ -d "$NEW_SNAP_PATH" ]; then
    echo "⚠️ Snapshot already exists for today. Skipping creation."
else
    btrfs subvolume snapshot -r / "$NEW_SNAP_PATH"
fi
sync

# 4. Incremental Logic
if [ -L "$LATEST_LINK" ]; then
    PARENT_PATH_USB=$(readlink -f "$LATEST_LINK")
    PARENT_NAME=$(basename "$PARENT_PATH_USB")
    
    # Check if the parent version still exists on your SSD
    if [ -d "${SNAP_DIR}/${PARENT_NAME}" ]; then
        echo "⚡ Mode: Incremental (Sending changes since ${PARENT_NAME})"
        btrfs send -p "${SNAP_DIR}/${PARENT_NAME}" "$NEW_SNAP_PATH" | pv | btrfs receive "$MOUNT_POINT/"
    else
        echo "⚠️ Parent ${PARENT_NAME} missing from SSD. Falling back to Full Backup..."
        btrfs send "$NEW_SNAP_PATH" | pv | btrfs receive "$MOUNT_POINT/"
    fi
else
    echo "📦 Mode: Initial Full Backup (First time only)..."
    btrfs send "$NEW_SNAP_PATH" | pv | btrfs receive "$MOUNT_POINT/"
fi

# 5. Update USB Pointer
echo "🔗 Updating 'latest' pointer..."
rm -f "$LATEST_LINK"  # Delete the old link first
ln -sf "${MOUNT_POINT}/${NEW_SNAP_NAME}" "$LATEST_LINK"

# 6. Cleanup Local SSD (Keep ONLY the current one for next week)
echo "🧹 Cleaning up old local snapshots..."
find "$SNAP_DIR" -maxdepth 1 -name "root_backup_*" -not -name "$NEW_SNAP_NAME" -exec btrfs subvolume delete {} \; 2>/dev/null || true

# 7. Finish
sync
umount "$MOUNT_POINT"
echo "✅ Done! Weekly backup complete in record time."
