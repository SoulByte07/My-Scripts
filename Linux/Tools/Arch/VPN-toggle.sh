#!/bin/bash

# --- Paths ---
PROTON_BIN="/usr/bin/protonvpn"
NOTIFY_BIN="/usr/bin/notify-send"

# --- DNS Commands ---
DNS_OFF="pkexec sh -c 'mv /etc/systemd/resolved.conf.d/nextdns.conf /etc/systemd/resolved.conf.d/nextdns.conf.bak && systemctl restart systemd-resolved'"
DNS_ON="pkexec sh -c 'mv /etc/systemd/resolved.conf.d/nextdns.conf.bak /etc/systemd/resolved.conf.d/nextdns.conf && systemctl restart systemd-resolved'"

# --- Rofi Menu ---
OPTIONS="Connect\nDisconnect"
CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -p "Proton VPN" -theme ~/.config/rofi/themes/KooL_Catppuccin_mocha.rasi -theme-str 'listview { columns: 2; lines: 1; }')

[[ -z "$CHOSEN" ]] && exit

case "$CHOSEN" in
    Connect)
        eval "$DNS_OFF"
        
        # Capture the output of the connect command
        OUTPUT=$($PROTON_BIN connect 2>&1)
        
        if [ $? -eq 0 ]; then
            # Parse the location and IP from the output you shared
            # Example: "Connected to NL-FREE#164 in Amsterdam, Netherlands. Your new IP address is 185.107.80.87."
            LOCATION=$(echo "$OUTPUT" | grep -oP 'in \K.*?(?=\.)')
            IP=$(echo "$OUTPUT" | grep -oP 'is \K.*?(?=\.)')
            
            $NOTIFY_BIN "VPN Active" "📍 $LOCATION\n🌐 $IP" -i network-vpn
        else
            eval "$DNS_ON"
            $NOTIFY_BIN "VPN Error" "Failed to connect" -u critical -i dialog-error
        fi
        ;;
    Disconnect)
        if $PROTON_BIN disconnect; then
            eval "$DNS_ON"
            $NOTIFY_BIN "VPN Down" "NextDNS Restored" -i network-disconnect
        else
            $NOTIFY_BIN "VPN Error" "Failed to disconnect" -u critical -i dialog-error
        fi
        ;;
esac
