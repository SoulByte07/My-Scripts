#!/bin/bash

# --- Configuration ---
SOURCE="$HOME/4_Backups/0_Sync"
REMOTE="EncryptGoogleDrive:0_Sync"
LOG_DIR="$HOME/2_Resources/97_Logs/rclone"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$LOG_DIR/$DATE.log"

# --- Safety Check ---
# Create the log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# --- Rclone Command ---
rclone copy "$SOURCE" "$REMOTE" \
    --create-empty-src-dirs \
    --log-file="$LOG_FILE" \
    --log-level INFO \
    --progress

echo "Sync complete. Log saved to $LOG_FILE"
