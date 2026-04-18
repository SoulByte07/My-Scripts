#!/usr/bin/env python3
"""
setup_wizard.py
Interactively configures local paths for the SOPS vault.
Cross-platform and enforces strict file permissions.

Sample Input (CLI):
    $ ./setup_wizard.py
    === SOPS Vault Setup Wizard ===
    Let's configure your local environment. These settings will NOT be committed to Git.

    Question: Where is your AGE SSH private key located?
      Example (Linux/Mac): ~/.ssh/id_ed25519
      Example (Windows):   C:\\Users\\Name\\.ssh\\id_ed25519
      Default: ~/.ssh/shh_1221
    Enter path (press Enter for default): 

Expected Output:
    Success! Configuration securely saved to .vault_config.json (Owner read/write only).
    You can now run `./env_vault.py` daily.
"""

import json
import os
import stat
from pathlib import Path

CONFIG_FILE = Path(".vault_config.json")
DEFAULT_KEY = "~/.ssh/shh_1221"


def save_secure_config(data: dict) -> None:
    """Saves JSON data with strict 0600 (owner read/write) permissions cross-platform."""
    # os.O_WRONLY: Write only
    # os.O_CREAT: Create if it doesn't exist
    # os.O_TRUNC: Truncate (overwrite) if it does exist
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    
    # stat.S_IRUSR | stat.S_IWUSR forces 0600 permissions (Owner Read/Write)
    mode = stat.S_IRUSR | stat.S_IWUSR 
    
    # Securely open the file descriptor, then wrap it in Python's standard file object
    with os.fdopen(os.open(CONFIG_FILE, flags, mode), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)


def main() -> None:
    print("=== SOPS Vault Setup Wizard ===")
    print("Let's configure your local environment. These settings will NOT be committed to Git.\n")

    # Ask question, give examples, show default
    print("Question: Where is your AGE SSH private key located?")
    print("  Example (Linux/Mac): ~/.ssh/id_ed25519")
    print("  Example (Windows):   C:\\Users\\Name\\.ssh\\id_ed25519")
    print(f"  Default: {DEFAULT_KEY}")
    
    # Read the input
    user_input = input("Enter path (press Enter for default): ").strip()
    
    # If null, use default, else use input
    key_file = user_input if user_input else DEFAULT_KEY

    config_data = {
        "key_file": key_file
    }

    # Save securely
    save_secure_config(config_data)
    
    print(f"\nSuccess! Configuration securely saved to {CONFIG_FILE} (Owner read/write only).")
    print("You can now run `./env_vault.py` daily.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nInterrupted by user.")
        raise SystemExit(130)
