#!/bin/bash
# Phone-Mic: Stream Android mic to PipeWire virtual source via Rofi
# Pre-requisites: scrcpy with audio support, PipeWire, pactl, rofi, libnotify

SINK_NAME="MobileMic"
SOURCE_NAME="MobileMic_Source"

function start_mic() {
    # 1. Check for existing connection
    if pgrep -f "scrcpy.*--audio-source=mic" > /dev/null; then
        notify-send "Phone Mic" "Already connected."
        exit 0
    fi

    notify-send "Phone Mic" "Connecting..."
    
    # 2. Load virtual audio nodes
    pactl load-module module-null-sink sink_name=$SINK_NAME sink_properties=device.description=$SINK_NAME > /dev/null
    pactl load-module module-remap-source master=$SINK_NAME.monitor source_name=$SOURCE_NAME source_properties=device.description=$SOURCE_NAME > /dev/null
    
    # 3. Launch Scrcpy in the background
    export SDL_AUDIODRIVER=pulseaudio
    PULSE_SINK=$SINK_NAME scrcpy --no-video --no-window --audio-source=mic > /tmp/phone-mic.log 2>&1 &
    
    # 4. Fast Polling: Catch the stream instantly to prevent speaker feedback
    # We loop up to 20 times, waiting 0.2 seconds each time (max 4 seconds)
    for i in {1..20}; do
        # Extract the Sink Input ID by checking whole blocks for SDL or scrcpy
        SINK_IDS=$(pactl list sink-inputs | awk -v RS='' '/SDL Application|scrcpy/ {print $3}' | tr -d '#')
        
        if [ -n "$SINK_IDS" ]; then
            for ID in $SINK_IDS; do
                # Move the stream to MobileMic
                pactl move-sink-input "$ID" "$SINK_NAME" 2>/dev/null
            done
            
            # Set MobileMic as default recording device
            pactl set-default-source "$SOURCE_NAME" 2>/dev/null
            
            notify-send "Phone Mic" "Connected & Routed!"
            return # Exit the function successfully
        fi
        sleep 0.2
    done
    
    # If the loop finishes without finding the stream, it failed
    notify-send -u critical "Phone Mic" "Routing failed. Check USB/ADB."
    stop_mic 
}

function stop_mic() {
    if pgrep -f "scrcpy.*--audio-source=mic" > /dev/null; then
        pkill -f "scrcpy.*--audio-source=mic"
        notify-send "Phone Mic" "Disconnected."
    else
        notify-send "Phone Mic" "No active connection found."
    fi
    
    pactl unload-module module-remap-source 2>/dev/null || true
    pactl unload-module module-null-sink 2>/dev/null || true
}

# 5. Rofi Menu
CHOICE=$(echo -e "Connect\nDisconnect" | rofi -dmenu -i -p "Android Mic:" -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi -theme-str 'listview { columns: 1; lines: 2; }')
case "$CHOICE" in
    "Connect") start_mic ;;
    "Disconnect") stop_mic ;;
    *) exit 0 ;;
esac
