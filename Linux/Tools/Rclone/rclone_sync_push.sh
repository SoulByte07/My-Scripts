#!/bin/bash
# usage: run this script to sync from local to Google Drive, with safety measures and logging and get notifications on completion or failure.
# --- Configuration ---
# Set the date first to use in paths
DATE=$(date +%d-%b-%y_%H-%M)

# Path definitions
SOURCE="$HOME/4_Backups/0_Sync"
REMOTE="EncryptGoogleDrive:0_Sync"
# Trash is kept on the remote to save local disk space
TRASH_DIR="EncryptGoogleDrive:96_Trash/0_Sync/$DATE"
LOG_DIR="$HOME/2_Resources/97_Logs/rclone"
LOG_FILE="$LOG_DIR/$DATE.log"

# --- Safety Check ---
# Ensure log directory exists
mkdir -p "$LOG_DIR"

# --- Rclone Sync Function ---
run_sync() {
    # Syncing Local to Remote
    rclone sync "$SOURCE" "$REMOTE" \
        --fast-list \
        --backup-dir "$TRASH_DIR" \
        --create-empty-src-dirs \
        --log-file="$LOG_FILE" \
        --log-level INFO \
        --max-delete 50 \
        --use-mmap

    # Check if rclone exited successfully (exit code 0)
    if [ $? -eq 0 ]; then
        notify-send "Rclone Backup" "Upload successful! Log: $DATE.log" -i drive-harddisk
    else
        notify-send "Rclone Backup" "Upload FAILED! Check logs at $LOG_FILE" -u critical -i dialog-error
    fi
}

# Run the function in the background and discard terminal output
run_sync > /dev/null 2>&1 &
