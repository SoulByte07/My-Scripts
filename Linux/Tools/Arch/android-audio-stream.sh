#!/bin/bash

# Configuration port
PORT=8080

# Trigger rofi immediately for instant UI feedback
CHOICE=$(echo -e "Connect\nDisconnect" | rofi -dmenu -p "Android Stream:" -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi -theme-str 'listview { columns: 2; lines: 1; }')

case "$CHOICE" in
    Connect)
        # 1. Fetch the sink ONLY if the user chooses to connect
        SOURCE="$(pactl get-default-sink).monitor"
        
        # 2. Mute the local laptop speaker
        pactl set-sink-mute @DEFAULT_SINK@ 1
        
        # 3. Load the TCP protocol module
        pactl load-module module-simple-protocol-tcp \
            source="$SOURCE" \
            record=true \
            port=$PORT \
            rate=48000 \
            format=s16le \
            channels=2
        
        # 4. Get LAN IP and notify
        IP=$(ip route get 1 | awk '{print $7; exit}')
        notify-send "Audio Stream Started" "Streaming $IP:$PORT" -u critical
        ;;
        
    Disconnect)
        # 1. Find the active module ID (Combined grep into awk to save a process)
        MODULE_IDS=$(pactl list short modules | awk '/module-simple-protocol-tcp/ {print $1}')
        
        if [ -z "$MODULE_IDS" ]; then
            notify-send "No active stream found."
        else
            # 2. Loop through and unload
            for ID in $MODULE_IDS; do
                pactl unload-module "$ID"
            done
            
            # 3. Unmute the local laptop speaker
            pactl set-sink-mute @DEFAULT_SINK@ 0
            
            # 4. Notify user
            notify-send "Stream stopped" "Audio restored to laptop."
        fi
        ;;
        
    *)
        # Exit cleanly
        exit 0
        ;;
esac

# --- Sample Usage ---
# Input: Execute the script via a terminal or a Hyprland keybind.
# Expected Output: Rofi menu appears instantly. Selecting "Connect" routes audio over TCP and triggers a notification: "Audio Stream Started: Streaming 192.168.x.x:8080".
