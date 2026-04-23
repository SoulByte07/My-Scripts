#!/bin/bash

# Setup directories
save_dir="$HOME/Pictures/Screenshots"
mkdir -p "$save_dir"
filename="$save_dir/screenshot_$(date +%Y%m%d_%H%M%S).png"
log_file="/tmp/screenshot_debug.log"
> "$log_file"

# Menu options for tofi
options="Region (Direct)\nFull (Direct)\nTimer 5s (Direct)\nTimer 10s (Direct)\nRegion (Edit)\nFull (Edit)\nTimer 5s (Edit)\nTimer 10s (Edit)"

#choice=$(echo -e "$options" | tofi \
#    --prompt-text "ScreenShot: " \
#    --num-results 8 \
#    --font "FiraCode Nerd Font" \
#    --ascii-input=false \
#    --fuzzy-match=false)
choice=$(echo -e "$options" | rofi -dmenu -i -p "ScreenShot: " \
    -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi \
    -theme-str 'listview { columns: 2; lines: 4; }')


# Function: Capture with Satty Editor
# Sample Input: User selects "Region (Edit)" in Tofi, draws a box.
# Expected Output: Satty opens the snippet with rounded corners, FiraCode font, brush tool active, and no window decorations for a clean Hyprland look.

capture_edit() {
    local area=$1
    
    # Store all our desired settings from the manual in an array for clean reading
    local satty_flags=(
        "--fullscreen"
        "--output-filename" "$filename"
        "--font-family" "FiraCode Nerd Font"
        "--initial-tool" "brush"
        "--corner-roundness" "12"
        "--no-window-decoration" 
    )

    if [ -n "$area" ]; then
        # Pipe region into satty with our custom flags
        grim -g "$area" - | satty --filename - "${satty_flags[@]}"
    else
        # Pipe full screen into satty with our custom flags
        grim - | satty --filename - "${satty_flags[@]}"
    fi
    
    [ $? -eq 0 ] && notify-send "Screenshot" "Editor closed."
}

# Function: Capture Direct (Save & Copy)
capture_direct() {
    local area=$1
    if [ -n "$area" ]; then
        grim -g "$area" "$filename"
    else
        grim "$filename"
    fi
    
    if [ $? -eq 0 ]; then
        wl-copy < "$filename"
        notify-send "Screenshot" "Saved & Copied: $(basename "$filename")"
    fi
}

# Decision Logic
case "$choice" in
    "Region (Edit)")
        area=$(slurp < /dev/null)
        [ -n "$area" ] && capture_edit "$area"
        ;;
    "Full (Edit)")
        capture_edit
        ;;
    "Timer 5s (Edit)")
        sleep 5 && capture_edit
        ;;
    "Timer 10s (Edit)")
        sleep 10 && capture_edit
        ;;
    "Region (Direct)")
        area=$(slurp < /dev/null)
        [ -n "$area" ] && capture_direct "$area"
        ;;
    "Full (Direct)")
        capture_direct
        ;;
    "Timer 5s (Direct)")
        sleep 5 && capture_direct
        ;;
    "Timer 10s (Direct)")
        sleep 10 && capture_direct
        ;;
    *)
        exit 0
        ;;
esac
