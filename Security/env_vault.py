#!/usr/bin/env python3
"""
env_vault.py
Encrypt/decrypt env files with SOPS in team-safe way using atomic writes.

Sample Input (CLI):
    $ ./env_vault.py encrypt --vault-dir secrets --plain-dir locals

Expected Output:
    PROCESS locals/.env.staging -> secrets/.env.staging
    OK   locals/.env.staging -> secrets/.env.staging
    Done. mode=encrypt processed=1 skipped=0 failed=0
"""

from __future__ import annotations

import argparse
import os
import shutil
import stat
import subprocess
import sys
from enum import IntEnum
from pathlib import Path
from typing import Iterable

DEFAULT_AGE_KEY_FILE = "~/.ssh/shh_1221"
DEFAULT_PLAIN_DIR = ".env.local"
DEFAULT_VAULT_DIR = ".env"

# Standardized SOPS environment variable for age keys
SOPS_ENV_KEY = "SOPS_AGE_KEY_FILE"

class ExitCode(IntEnum):
    OK = 0
    USAGE_ERROR = 2
    DEPENDENCY_MISSING = 3
    CONFIG_ERROR = 4
    PROCESSING_ERROR = 5


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def path_within(base: Path, candidate: Path) -> bool:
    try:
        candidate.relative_to(base)
        return True
    except ValueError:
        return False


def list_source_files(src_dir: Path, recursive: bool) -> list[Path]:
    items: Iterable[Path] = src_dir.rglob("*") if recursive else src_dir.iterdir()
    files: list[Path] = []
    for item in items:
        if item.is_symlink():
            print(f"SKIP symlink: {item}")
            continue
        if item.is_file():
            files.append(item)
    files.sort()
    return files


def build_destination(src_root: Path, dst_root: Path, src_file: Path, recursive: bool) -> Path:
    rel = src_file.relative_to(src_root) if recursive else Path(src_file.name)
    dst = (dst_root / rel).resolve(strict=False)
    dst_root_resolved = dst_root.resolve(strict=False)
    if not path_within(dst_root_resolved, dst):
        raise ValueError(f"Refusing to write outside destination directory: {dst}")
    return dst


def check_dependency_sops() -> bool:
    return shutil.which("sops") is not None


def validate_key_file(key_file: Path) -> tuple[bool, str]:
    if not key_file.exists() or not key_file.is_file():
        return False, f"Key file not found or not file: {key_file}"
    return True, ""


def run_sops_file(
    sops_mode_flag: str,
    src_file: Path,
    dst_file: Path,
    key_file: Path,
    chmod_600: bool,
    dry_run: bool,
    verbose: bool,
) -> tuple[bool, str]:
    if verbose or dry_run:
        prefix = "DRY-RUN " if dry_run else ""
        print(f"{prefix}PROCESS {src_file} -> {dst_file}")

    if dry_run:
        return True, ""

    dst_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Use a temporary file for atomic writes
    tmp_dst_file = dst_file.with_suffix('.tmp')

    cmd = ["sops", sops_mode_flag, "--output", str(tmp_dst_file), str(src_file)]
    env = os.environ.copy()
    env[SOPS_ENV_KEY] = str(key_file)

    proc = subprocess.run(cmd, env=env, capture_output=True, text=True, check=False)

    if proc.returncode != 0:
        # Clean up the temporary file on failure, leaving the original destination intact
        if tmp_dst_file.exists():
            tmp_dst_file.unlink(missing_ok=True)
        err = (proc.stderr or "").strip() or f"sops exited with code {proc.returncode}"
        return False, err

    # Apply permissions to the temp file before moving it into place
    if chmod_600:
        try:
            os.chmod(tmp_dst_file, stat.S_IRUSR | stat.S_IWUSR)
        except OSError as exc:
            tmp_dst_file.unlink(missing_ok=True)
            return False, f"Could not set 0600 permissions on temp file: {exc}"

    # Atomically replace the old file with the new one
    tmp_dst_file.replace(dst_file)

    return True, ""


def process_mode(
    mode: str,
    key_file: Path,
    plain_dir: Path,
    vault_dir: Path,
    recursive: bool,
    overwrite: bool,
    chmod_600: bool,
    dry_run: bool,
    verbose: bool,
) -> ExitCode:
    plain_dir.mkdir(parents=True, exist_ok=True)
    vault_dir.mkdir(parents=True, exist_ok=True)

    if mode == "encrypt":
        source_dir, target_dir, sops_flag = plain_dir, vault_dir, "-e"
    elif mode == "decrypt":
        source_dir, target_dir, sops_flag = vault_dir, plain_dir, "-d"
    else:
        eprint(f"Invalid mode: {mode}")
        return ExitCode.USAGE_ERROR

    files = list_source_files(source_dir, recursive=recursive)
    if not files:
        print(f"No files to process in: {source_dir}")
        return ExitCode.OK

    valid_key, key_err = validate_key_file(key_file)
    if not valid_key:
        eprint(f"ERROR: {key_err}")
        return ExitCode.CONFIG_ERROR

    failed = processed = skipped = 0

    for src in files:
        try:
            dst = build_destination(source_dir, target_dir, src, recursive=recursive)
        except ValueError as exc:
            eprint(f"FAIL {src}: {exc}")
            failed += 1
            continue

        if dst.exists() and not overwrite:
            print(f"SKIP exists (overwrite disabled): {dst}")
            skipped += 1
            continue

        success, message = run_sops_file(
            sops_mode_flag=sops_flag,
            src_file=src,
            dst_file=dst,
            key_file=key_file,
            chmod_600=chmod_600,
            dry_run=dry_run,
            verbose=verbose,
        )

        if success:
            print(f"OK   {src} -> {dst}")
            processed += 1
        else:
            eprint(f"FAIL {src} -> {dst}: {message}")
            failed += 1

    print(f"Done. mode={mode} processed={processed} skipped={skipped} failed={failed}")
    return ExitCode.OK if failed == 0 else ExitCode.PROCESSING_ERROR


def interactive_mode_prompt() -> str:
    print("Choose action:\n  1) Encrypt (default)\n  2) Decrypt")
    while True:
        choice = input("Enter choice [1/2]: ").strip()
        if choice in ("", "1"):
            return "encrypt"
        if choice == "2":
            return "decrypt"
        print("Invalid choice. Please enter 1 or 2.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Encrypt/decrypt env files with SOPS safely.")
    
    parser.add_argument("command", nargs="?", choices=("encrypt", "decrypt"), help="Operation mode. If omitted, interactive prompt is used.")
    parser.add_argument("--key-file", default=DEFAULT_AGE_KEY_FILE, help="Path to AGE SSH private key file.")
    parser.add_argument("--plain-dir", default=DEFAULT_PLAIN_DIR, help="Directory with plaintext env files.")
    parser.add_argument("--vault-dir", default=DEFAULT_VAULT_DIR, help="Directory with encrypted env files.")

    # Using BooleanOptionalAction for much cleaner boolean flag definitions (Python 3.9+)
    parser.add_argument("--recursive", action=argparse.BooleanOptionalAction, default=False, help="Process directories recursively.")
    parser.add_argument("--overwrite", action=argparse.BooleanOptionalAction, default=True, help="Overwrite existing destination files.")
    parser.add_argument("--chmod-600", action=argparse.BooleanOptionalAction, default=True, help="Set output file mode to 0600.")
    
    parser.add_argument("-i", "--interactive", action="store_true", help="Force interactive menu if command is omitted.")
    parser.add_argument("--dry-run", action="store_true", help="Show what would run without executing sops.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose logs (never prints file contents).")
    
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not check_dependency_sops():
        eprint("ERROR: `sops` not available in PATH.")
        return ExitCode.DEPENDENCY_MISSING

    key_file = Path(args.key_file).expanduser().resolve(strict=False)
    plain_dir = Path(args.plain_dir).expanduser().resolve(strict=False)
    vault_dir = Path(args.vault_dir).expanduser().resolve(strict=False)

    command = args.command
    if command is None:
        if args.interactive or sys.stdin.isatty():
            command = interactive_mode_prompt()
        else:
            eprint("ERROR: command required in non-interactive mode: encrypt|decrypt")
            return ExitCode.USAGE_ERROR

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
