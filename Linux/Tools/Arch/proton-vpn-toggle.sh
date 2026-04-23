#!/bin/bash
# Professional VPN Manager for Arch-Hyprland
# Ensures strictly ONE active tunnel and enforces NextDNS DoH.

# --- Configuration Variables ---
# Replace these with your exact nmcli connection names if they differ
VPN_SPEED="ProtonSpeedSP"
VPN_STABILITY="VPN_Stable"
VPN_PRIVACY="ProtonPrivSL"

# --- Function: The Gatekeeper ---
# Finds and shuts down ANY active VPN to prevent routing deadlocks
disconnect_active_vpns() {
    # Get a list of all active connections that are VPNs or WireGuard
    local active_vpns
    active_vpns=$(nmcli -t -f NAME,TYPE connection show --active | grep -iE 'wireguard|vpn' | cut -d: -f1)
    
    if [ -n "$active_vpns" ]; then
        # Loop through and disconnect them one by one
        while IFS= read -r vpn; do
            nmcli connection down "$vpn"
        done <<< "$active_vpns"
        return 0 # Successfully disconnected something
    fi
    return 1 # Nothing was active
}

# --- Main Logic ---

# 1. First Rofi Menu: Action Selection
ACTION=$(echo -e "󰒄 Connect\n󰅖 Disconnect" | rofi -dmenu -i -p "Proton VPN: " \
    -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi \
    -theme-str 'listview { columns: 2; lines: 1; }')

case "$ACTION" in
    *Disconnect*)
        # Execute disconnect and notify
        if disconnect_active_vpns; then
            notify-send "Shield Off" "All tunnels closed. Fallback to native NextDNS." -i network-offline
        else
            notify-send "Shield Status" "No VPN is currently active." -i dialog-information
        fi
        ;;
    
    *Connect*)
        # 2. Second Rofi Menu: Profile Selection
        PROFILE=$(echo -e "⚡ Speed (Singapore)\n🛡️ Stability (Mexico)\n🕵️ Privacy (Swizerland)" | rofi -dmenu -i -p "Proton VPN Type: " \
    -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi \
    -theme-str 'listview { columns: 1; lines: 3; }')
 
        
        # Map choice to exact connection name
        case "$PROFILE" in
            *Speed*) TARGET_VPN="$VPN_SPEED" ;;
            *Stability*) TARGET_VPN="$VPN_STABILITY" ;;
            *Privacy*) TARGET_VPN="$VPN_PRIVACY" ;;
            *) exit 0 ;; # User pressed escape
        esac

        notify-send "Shield On" "Preparing tunnel for $PROFILE..." -i network-transmit-receive
        
        # 3. SAFETY ENFORCEMENT: Kill existing connections before starting the new one
        disconnect_active_vpns
        
        # 4. Initiate Connection
        if nmcli connection up "$TARGET_VPN"; then
            notify-send "Success" "Connected to $PROFILE. NextDNS DoH is routing securely." -i network-vpn
        else
            notify-send "Error" "Failed to connect. Check hotspot or Proton server load." -u critical
        fi
        ;;
        
    *)
        # User pressed escape on the first menu
        exit 0
        ;;
esac
