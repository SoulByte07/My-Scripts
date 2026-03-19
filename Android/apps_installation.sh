#!/bin/bash

# Description: Advanced Android APK installer for local and remote sources
# Sample Input (apk_list.txt):
# /home/soul/Downloads/app.apk
# https://example.com/direct_link.apk
# https://github.com/checkstyle/checkstyle (Example repo)

# 1. Check ADB Connection
if ! adb devices | grep -q -w "device"; then
    echo "❌ No device found. Check your USB/Wireless debugging."
    exit 1
fi

TEMP_DIR=$(mktemp -d)

# 2. Process the list
while IFS= read -r source || [ -n "$source" ]; do
    # Skip empty lines or comments
    [[ -z "$source" || "$source" =~ ^# ]] && continue

    echo "--- Processing: $source ---"
    INSTALL_TARGET=""

    if [[ -f "$source" ]]; then
        # Handle Local File
        INSTALL_TARGET="$source"
    elif [[ "$source" == *"github.com"* ]]; then
        # Handle GitHub Repo (Scrape latest release APK)
        echo "🔍 Finding latest GitHub release..."
        # This finds the first .apk link in the latest release page
        INSTALL_TARGET="$TEMP_DIR/gh_app.apk"
        DOWNLOAD_URL=$(curl -s "$source/releases/latest" | grep -oP '/releases/download/[^"]+\.apk' | head -n 1)
        curl -L "https://github.com$DOWNLOAD_URL" -o "$INSTALL_TARGET"
    elif [[ "$source" == http* ]]; then
        # Handle Direct URL
        echo "🌐 Downloading direct link..."
        INSTALL_TARGET="$TEMP_DIR/web_app.apk"
        curl -L "$source" -o "$INSTALL_TARGET"
    fi

    # 3. Execution Phase
    if [[ -f "$INSTALL_TARGET" ]]; then
        echo "🚀 Installing..."
        adb install -r "$INSTALL_TARGET"
    else
        echo "⚠️  Could not resolve or download: $source"
    fi

done < apk_list.txt

# 4. Cleanup
rm -rf "$TEMP_DIR"
echo "✅ All tasks processed."
