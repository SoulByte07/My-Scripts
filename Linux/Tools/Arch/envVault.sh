#!/bin/bash
# envVault.sh - Soul's Arch Secret Manager

# 1. THE KEY: Direct path to your github-specific private key
export SOPS_AGE_SSH_PRIVATE_KEY_FILE="$HOME/.ssh/github/arch-soul"

PLAIN_DIR=".env.local"
VAULT_DIR=".env"

# Ensure directories exist
mkdir -p $PLAIN_DIR $VAULT_DIR

# 2. USER INTERFACE: Interactive Menu
echo "--- SOPS VAULT MANAGER ---"
echo "1) Encrypt (Push: $PLAIN_DIR -> $VAULT_DIR) [DEFAULT]"
echo "2) Decrypt (Local: $VAULT_DIR -> $PLAIN_DIR)"
echo "--------------------------"
read -p "Select option [1]: " choice

# Default to 1 if user just presses Enter
choice=${choice:-1}

case $choice in
  1)
    echo "🔒 Locking files for Git..."
    # Check if there are any files to encrypt
    if [ -n "$(ls -A $PLAIN_DIR 2>/dev/null)" ]; then
        for file in $PLAIN_DIR/*; do
            filename=$(basename "$file")
            # Encrypt from source to destination (maintains same filename)
            sops -e "$file" > "$VAULT_DIR/$filename" && echo "✅ Encrypted: $filename"
        done
        echo "🚀 Ready to push. Track the '$VAULT_DIR' folder in Git."
    else
        echo "⚠️  No files found in $PLAIN_DIR to encrypt."
    fi
    ;;

  2)
    echo "🔓 Unlocking files for Local Dev..."
    # Check if there are any encrypted files
    if [ -n "$(ls -A $VAULT_DIR 2>/dev/null)" ]; then
        for file in $VAULT_DIR/*; do
            filename=$(basename "$file")
            # Decrypt from vault to local (maintains same filename)
            if sops -d "$file" > "$PLAIN_DIR/$filename"; then
                echo "✅ Decrypted: $filename"
            else
                echo "❌ FAILED: Could not decrypt $filename (Check your SSH key)"
            fi
        done
        echo "💻 Done. Use files in $PLAIN_DIR for your code."
    else
        echo "⚠️  No files found in $VAULT_DIR to decrypt."
    fi
    ;;

  *)
    echo "❌ Invalid option. Exiting."
    exit 1
    ;;
esac
