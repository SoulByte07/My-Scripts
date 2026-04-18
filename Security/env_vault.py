#!/usr/bin/env python3
"""
env_vault.py
Encrypt/decrypt env files using settings from the local setup wizard.

Sample Input (CLI):
    $ ./env_vault.py encrypt

Expected Output:
    Loaded config from .vault_config.json
    OK   .env.local/db.env -> .env/db.env
    Done. mode=encrypt processed=1 skipped=0 failed=0
"""

# ... [Keep all imports and helper functions from the previous version] ...

import json

CONFIG_FILE = Path(".vault_config.json")

def load_config() -> dict[str, str]:
    """Loads configuration from the wizard-generated JSON file."""
    if not CONFIG_FILE.exists():
        return {}
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError:
        eprint(f"ERROR: {CONFIG_FILE} is corrupted. Please run setup_wizard.py again.")
        raise SystemExit(4)

def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not check_dependency_sops():
        eprint("ERROR: `sops` not available in PATH.")
        return ExitCode.DEPENDENCY_MISSING

    # 1. Load config from the wizard
    config = load_config()

    if not config and not args.key_file:
        eprint("ERROR: No configuration found. Please run `./setup_wizard.py` first.")
        return ExitCode.CONFIG_ERROR

    # 2. Command line args override wizard config, which overrides defaults
    raw_key = args.key_file if args.key_file != DEFAULT_AGE_KEY_FILE else config.get("key_file", DEFAULT_AGE_KEY_FILE)
    raw_plain = args.plain_dir if args.plain_dir != DEFAULT_PLAIN_DIR else config.get("plain_dir", DEFAULT_PLAIN_DIR)
    raw_vault = args.vault_dir if args.vault_dir != DEFAULT_VAULT_DIR else config.get("vault_dir", DEFAULT_VAULT_DIR)

    # 3. Resolve paths
    key_file = Path(raw_key).expanduser().resolve(strict=False)
    plain_dir = Path(raw_plain).expanduser().resolve(strict=False)
    vault_dir = Path(raw_vault).expanduser().resolve(strict=False)

    command = args.command
    if command is None:
        if args.interactive or sys.stdin.isatty():
            command = interactive_mode_prompt()
        else:
            eprint("ERROR: command required in non-interactive mode: encrypt|decrypt")
            return ExitCode.USAGE_ERROR

    print(f"Loaded config. Using Key: {key_file}")

    result = process_mode(
        mode=command,
        key_file=key_file,
        plain_dir=plain_dir,
        vault_dir=vault_dir,
        recursive=args.recursive,
        overwrite=args.overwrite,
        chmod_600=args.chmod_600,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )
    return int(result)

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        eprint("\nInterrupted by user.")
        raise SystemExit(130)
