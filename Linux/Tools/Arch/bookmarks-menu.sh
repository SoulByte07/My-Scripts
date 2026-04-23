#!/bin/sh
set -eu

# ==============================================================================
# 🔖 Rofi Bookmark Manager
# ==============================================================================
# Description: A lightning-fast, terminal-native bookmark manager using Rofi.
# Architecture: Treats the file system as the database itself.
#   - Folder Name = Tag / Category
#   - File Name   = Bookmark Name
#   - File Data   = Line 1: URL | Line 2: Target Browser
#
# Directory Structure Example:
# ~/.config/bookmarks/
# ├── work/
# │   └── Figma          <-- (Line 1: https://figma.com | Line 2: Chromium)
# └── personal/
#     └── Arch Wiki      <-- (Line 1: https://wiki.archlinux.org | Line 2: Librewolf)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Configuration & Dependencies
# ------------------------------------------------------------------------------
BM_DIR="${BM_DIR:-$HOME/4_Backups/0_Sync/Bookmarks}"
mkdir -p "$BM_DIR"

# Rofi UI Settings
ROFI_CMD="rofi -dmenu -i -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi"

# Browser Execution Paths (Prefers Flatpak if available, falls back to native)
LIBREWOLF="$(command -v flatpak >/dev/null 2>&1 && echo "flatpak run io.gitlab.librewolf-community" || echo librewolf)"
BRAVE="$(command -v flatpak >/dev/null 2>&1 && echo "flatpak run com.brave.Browser" || echo brave)"
CHROMIUM="$(command -v chromium || echo chromium)"

# ------------------------------------------------------------------------------
# 2. Core Engine: Data Retrieval
# ------------------------------------------------------------------------------
get_bookmarks() {
    # Provide the creation trigger as the very first menu option
    echo "[+] Add New Bookmark"
    
    # Recursively find all files, bypassing the root dir
    find "$BM_DIR" -mindepth 2 -type f | while IFS= read -r file; do
        
        # String manipulation to extract the folder tree and filename
        # Example: work/clients/google/Docs
        rel_path="${file#$BM_DIR/}"   # Strips the base directory path
        tag="${rel_path%/*}"          # Grabs everything before the last slash (Folder)
        name="${rel_path##*/}"        # Grabs everything after the last slash (File)
        
        # [OPTIMIZATION] Read directly into memory (0 child processes spawned)
        { read -r raw_url; } < "$file"
        
        # Sanitize data: Strip hidden carriage returns (\r) or trailing spaces
        url="$(printf '%s' "$raw_url" | tr -d '\r ')"
        
        # Output format fed directly into Rofi via pipe
        printf '[%s] %s: %s\n' "$tag" "$name" "$url"
    done
}

# Launch Rofi and capture the user's selection
choice="$(get_bookmarks | eval "$ROFI_CMD -p 'Bookmarks:'" || true)"
[ -n "$choice" ] || exit 0

# ==============================================================================
# FLOW 1: CREATE A NEW BOOKMARK
# ==============================================================================
if [ "$choice" = "[+] Add New Bookmark" ]; then
    
    # Step 1: Capture Bookmark Name
    name="$(echo "" | eval "$ROFI_CMD -p 'Name:'" || true)"
    [ -n "$name" ] || exit 0

    # Step 2: Capture URL
    url="$(echo "" | eval "$ROFI_CMD -p 'URL:'" || true)"
    [ -n "$url" ] || exit 0

    # Step 3: Capture or Create Tag (Folder)
    # Finds all existing folders to provide auto-complete options
    existing_tags="$(cd "$BM_DIR" && find . -mindepth 1 -type d | sed 's|^\./||' 2>/dev/null)"
    [ -n "$existing_tags" ] || existing_tags="personal\nwork"
    
    tag="$(printf "%b" "$existing_tags" | eval "$ROFI_CMD -p 'Assign Folder:'" || true)"
    [ -n "$tag" ] || exit 0

    # Step 4: Assign Specific Browser
    browser="$(printf "Librewolf\nBrave\nChromium" | eval "$ROFI_CMD -p 'Select Browser:'" || true)"
    [ -n "$browser" ] || exit 0

    # Step 5: Save to File System
    mkdir -p "$BM_DIR/$tag"
    printf "%s\n%s\n" "$url" "$browser" > "$BM_DIR/$tag/$name"
    
    notify-send "Bookmark Saved" "'$name' will open in $browser"
    exit 0
fi

# ==============================================================================
# FLOW 2: OPEN AN EXISTING BOOKMARK
# ==============================================================================

# Extract the selected tag and name from Rofi's formatted output string
# Expected String: "[work/project] Dashboard: https://url.com"
tag="${choice%%]*}"; tag="${tag#\[}"   # Extracts "work/project"
rest="${choice#*] }"
name="${rest%%: *}"                    # Extracts "Dashboard"

# Reconstruct the exact absolute file path
file_path="$BM_DIR/$tag/$name"

# Failsafe: Ensure file wasn't deleted outside the script
if [ ! -f "$file_path" ]; then
    notify-send "Bookmark Error" "Cannot find file: $file_path"
    exit 1
fi

# Extract URL (Line 1) and Browser (Line 2) natively into memory
{
    read -r raw_url
    read -r raw_browser
} < "$file_path"

# Sanitize variables just in case the file was edited manually
url="$(printf '%s' "$raw_url" | tr -d '\r ')"
saved_browser="$(printf '%s' "$raw_browser" | tr -d '\r ')"

# Auto-correct missing protocols
case "$url" in
    http://*|https://*|file://*|about:*|chrome:*) ;;
    *) url="https://$url" ;;
esac

# Function to execute the browser completely detached from the script & window manager
open_with() {
    cmd="$1"
    if [ -n "$cmd" ]; then
        # `setsid` prevents the browser from dying when Rofi/Script closes
        setsid $cmd "$url" >/dev/null 2>&1 &
        exit 0
    fi
}

# Route the URL to the designated browser
case "$saved_browser" in
    Librewolf) open_with "$LIBREWOLF" ;;
    Brave)     open_with "$BRAVE" ;;
    Chromium)  open_with "$CHROMIUM" ;;
    *)         open_with "$LIBREWOLF" ;; # Failsafe Fallback
esac
