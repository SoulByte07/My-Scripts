#!/bin/bash

# --- Configuration ---
DATE=$(date +%d-%b-%y_%H-%M)
SOURCE="$HOME/4_Backups/0_Sync"
REMOTE="EncryptGoogleDrive:0_Sync"
TRASH_DIR="$HOME/4_Backups/96_Trash/0_Sync/$DATE"
LOG_DIR="$HOME/2_Resources/97_Logs/rclone"
LOG_FILE="$LOG_DIR/$DATE.log"

# --- Safety Check ---
mkdir -p "$LOG_DIR"
mkdir -p "$TRASH_DIR"

# --- Rclone Sync Function ---
run_sync() {
    # We remove --progress for background runs to keep logs clean
    rclone sync "$REMOTE" "$SOURCE" \
        --fast-list \
        --backup-dir "$TRASH_DIR" \
        --create-empty-src-dirs \
        --log-file="$LOG_FILE" \
        --log-level INFO \
        --max-delete 50 \
        --use-mmap

    # Check if the last command (rclone) succeeded
    if [ $? -eq 0 ]; then
        notify-send "Rclone Sync" "Backup successful! Log: $DATE.log" -i drive-harddisk
    else
        notify-send "Rclone Sync" "Backup FAILED! Check logs at $LOG_FILE" -u critical -i dialog-error
    fi
}

# Run the function in the background and silence terminal output
run_sync > /dev/null 2>&1 &
