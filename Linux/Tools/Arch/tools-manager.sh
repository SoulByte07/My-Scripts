#!/bin/bash
# Description: Rofi dynamic script launcher with a custom theme
# Requirements: rofi, findutils

# 1. Define paths
SCRIPT_DIR="$HOME/.local/bin/Tools"


# Point this to your new custom theme file
THEME_PATH="~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi" 


# 2. Get the list of executable files
script_list=$(find "$SCRIPT_DIR" -maxdepth 2 -type f -executable -printf "%P\n")

# Sample Input (Files on disk): 
# ~/Tools/Arch/update.sh
# Expected Output (What shows in Rofi): 
# Arch/update.sh

# 3. Show the menu via Rofi using the custom theme
chosen=$(echo -e "$script_list" | rofi -dmenu -i -p "🚀 Run Tool: " -theme "$THEME_PATH")

# 4. Execute if a choice was made
if [ -n "$chosen" ]; then
    "$SCRIPT_DIR/$chosen" &
fi
