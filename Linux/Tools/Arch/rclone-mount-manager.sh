#!/bin/bash

# Define the menu options separated by newlines
OPTIONS="1. Mount Encrypted G-Drive\n3. Mount G-Drive\n2. Unmount Encrypted G-Drive\n4. Unmount G-Drive"

# Feed options into rofi and capture the user's choice
# -dmenu creates a selectable list, -i makes it case-insensitive, -p sets the prompt
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Drive Manager:" -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi -theme-str 'listview { columns: 2; lines: 2; }')

# Execute the corresponding systemctl command and send a notification
case "$CHOICE" in
    "1. Mount Encrypted G-Drive")
        systemctl --user start rclone-mount-encrypt-gdrive
        notify-send "Rclone Manager" "✅ Encrypted G-Drive Mounted"
        ;;
    "2. Unmount Encrypted G-Drive")
        systemctl --user stop rclone-mount-encrypt-gdrive
        notify-send "Rclone Manager" "🛑 Encrypted G-Drive Unmounted"
        ;;
    "3. Mount G-Drive")
        systemctl --user start rclone-mount-gdrive
        notify-send "Rclone Manager" "✅ G-Drive Mounted"
        ;;
    "4. Unmount G-Drive")
        systemctl --user stop rclone-mount-gdrive
        notify-send "Rclone Manager" "🛑 G-Drive Unmounted"
        ;;
    *)
        # Exit silently if the user presses Esc or clicks outside
        exit 0
        ;;
esac
