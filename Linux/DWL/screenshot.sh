#!/bin/bash

# Define directories and a debug log
save_dir="$HOME/Pictures/Screenshots"
log_file="/tmp/screenshot_debug.log"
mkdir -p "$save_dir"
filename="$save_dir/screenshot_$(date +%Y%m%d_%H%M%S).png"

# Clear out the old log file for a fresh start
> "$log_file"

# Define the menu options (Removed 'Window')
options="Region\nFull\nTimer 5 sec\nTimer 10 sec"

# Display options in tofi and store the user's selection
# Note: --num-results changed to 4
choice=$(echo -e "$options" | tofi \
    --prompt-text "ScreenShot: " \
    --num-results 4 \
    --ascii-input=false \
    --font="FiraCode Nerd Font" \
    --fuzzy-match=false
  )

# Execute the appropriate action based on the selection
case "$choice" in
    "Region")
#        sleep 0.5 
        
        # Detach from terminal state and capture errors
        area=$(slurp < /dev/null 2>> "$log_file")
        
        if [ -n "$area" ]; then
            if grim -g "$area" "$filename" 2>> "$log_file" && wl-copy < "$filename"; then
                notify-send "Screenshot" "Region saved and copied."
            else
                notify-send "Screenshot Error" "grim failed. Check $log_file"
            fi
        else
            notify-send "Screenshot Error" "slurp failed. Check $log_file"
        fi
        ;;
    "Full")
        if grim "$filename" 2>> "$log_file" && wl-copy < "$filename"; then
            notify-send "Screenshot" "Full screen saved and copied."
        fi
        ;;
    "Timer 5 sec")
        sleep 5
        if grim "$filename" && wl-copy < "$filename"; then
            notify-send "Screenshot" "Timer screenshot saved and copied."
        fi
        ;;
    "Timer 10 sec")
        sleep 10
        if grim "$filename" && wl-copy < "$filename"; then
            notify-send "Screenshot" "Timer screenshot saved and copied."
        fi
        ;;
    *)
        exit 1
        ;;
esac

# Sample Input: User triggers script via keybind, selects "Region".
# Expected Output: tofi closes. slurp safely grabs the pointer. User draws box. Saves to SSD, copies to clipboard. "Window" is no longer an option.
