#!/bin/bash
# cache_bg.sh

WALL_DIR="$HOME/Pictures/wallpapers"
CACHE_FILE="$HOME/.cache/wallpaper_cache.txt"

# 1. Build the cache ONLY if it doesn't exist, or if you pass the 'update' argument
# Now exclusively looking for .png files to save processing time
if [[ ! -f "$CACHE_FILE" ]] || [[ "$1" == "update" ]]; then
    find "$WALL_DIR" -type f -iname \*.png > "$CACHE_FILE"
fi

# 2. Pick a random PNG from the text file
RANDOM_IMG=$(shuf -n 1 "$CACHE_FILE")

# 3. Kill the old background process and set the new one quietly
pkill swaybg
swaybg -i "$RANDOM_IMG" -m fill &
