#!/usr/bin/env bash
# Soul's Ultra-Fast Fuzzel Launcher v2.0

# 1. Setup RAM Cache
CACHE="/tmp/fuzzel_pwa_cache.txt"

# 2. Build Cache: Name|FilePath|IconPath
gawk -F= '
    /^Name=/ && !n {n=$2}
    /^Icon=/ && !i {i=$2}
    ENDFILE {
        if(n) printf "%s|%s|%s\n", n, FILENAME, i;
        n=i=""
    }
' /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | sort -u > "$CACHE"

# 3. Format for Fuzzel (Injects the icon data on the fly)
SELECTED=$(gawk -F'|' '{printf "%s\0icon\x1f%s\n", $1, $3}' "$CACHE" | fuzzel --dmenu --prompt="❯ ")

# 4. Instant Lookup and Execute
if [[ -n "$SELECTED" ]]; then
    # Pass the selection securely to gawk, find exact match, print file path
    TARGET=$(gawk -F'|' -v sel="$SELECTED" '$1 == sel {print $2; exit}' "$CACHE")
    
    if [[ -n "$TARGET" ]]; then
        dex "$TARGET" >/dev/null 2>&1 &
    fi
fi

# Sample Input: Select "Gemini" in Fuzzel
# Expected Output: gawk finds "Gemini", extracts the exact file path, and dex launches it instantly.
