#!/bin/bash

# Change volume based on argument (+5%, -5%, or toggle)
case $1 in
    up)
        pamixer -i 5
        ;;
    down)
        pamixer -d 5
        ;;
    mute)
        pamixer -t
        ;;
esac

# Get current volume and mute status
VOLUME=$(pamixer --get-volume)
MUTE=$(pamixer --get-mute)

# Show notification using notify-send for mako
if [ "$MUTE" = "true" ]; then
    # Sample Input: Mute triggered
    # Expected Output: A Mako notification saying "Audio Muted"
    notify-send -a "Volume" -h string:x-canonical-private-synchronous:audio "Audio Muted"
else
    # Sample Input: Volume increased to 45%
    # Expected Output: A Mako notification saying "Volume: 45%" (with a progress bar if configured)
    notify-send -a "Volume" -h string:x-canonical-private-synchronous:audio -h int:value:"$VOLUME" "Volume: ${VOLUME}%"
fi
