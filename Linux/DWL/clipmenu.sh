#!/bin/bash
# Description: Pipes clipboard history to a tofi menu with UTF-8 support and a smaller font, then copies selection.

# Sample Input: Script execution (e.g., triggered by Super+v)
# Expected Output: Tofi UI opens with smaller text, displaying history properly. Selected text is copied.

# Use cliphist to list history, pipe to tofi with size, UTF-8, and font-size overrides, then decode and copy.
cliphist list | tofi \
  --prompt-text "Clipboard: " \
  --width 60% \
  --height 45% \
  --num-results 10 \
  --ascii-input=false \
  --font="FiraCode Nerd Font" \
  --font-size=15 \
  --fuzzy-match=true \
  | cliphist decode | wl-copy
