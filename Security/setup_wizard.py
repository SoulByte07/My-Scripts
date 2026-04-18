#!/usr/bin/env python3
"""
setup_wizard.py
Interactively configures local paths for the SOPS vault.

Sample Input (CLI):
    $ ./setup_wizard.py
    Enter path to your AGE SSH private key [~/.ssh/shh_1221]: 
    Enter directory for plaintext envs [.env.local]: 
    Enter directory for encrypted vault [.env]: 

Expected Output:
    Configuration saved to .vault_config.json! You can now use env_vault.py.
"""

import json
from pathlib import Path

CONFIG_FILE = Path(".vault_config.json")

def main() -> None:
    print("=== SOPS Vault Setup Wizard ===")
    print("Let's configure your local environment. These settings will NOT be committed to Git.\n")

    # Prompt user with defaults
    key_file = input("Enter path to your AGE SSH private key [~/.ssh/shh_1221]: ").strip() or "~/.ssh/shh_1221"
    plain_dir = input("Enter directory for plaintext envs [.env.local]: ").strip() or ".env.local"
    vault_dir = input("Enter directory for encrypted vault [.env]: ").strip() or ".env"

    config_data = {
        "key_file": key_file,
        "plain_dir": plain_dir,
        "vault_dir": vault_dir
    }

    # Save to local JSON file
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump(config_data, f, indent=4)
    
    print(f"\nSuccess! Configuration saved securely to {CONFIG_FILE}.")
    print("You can now run `./env_vault.py` daily.")

if __name__ == "__main__":
    main()
