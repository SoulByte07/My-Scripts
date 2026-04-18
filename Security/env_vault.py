#!/usr/bin/env python3
"""
env_vault.py
Encrypt/decrypt env files with SOPS in team-safe way.

Exit codes:
  0 = success
  2 = usage/input error
  3 = dependency missing
  4 = configuration/runtime precondition error
  5 = one or more file operations failed
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
DEFAULT_RECURSIVE = False
DEFAULT_OVERWRITE = True
DEFAULT_CHMOD_600 = True

SOPS_ENV_KEY = "SOPS_AGE_SSH_PRIVATE_KEY_FILE"


class ExitCode(IntEnum):
    OK = 0
    USAGE_ERROR = 2
    DEPENDENCY_MISSING = 3
    CONFIG_ERROR = 4
    PROCESSING_ERROR = 5


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def bool_from_args(value: bool | None, default: bool) -> bool:
    return default if value is None else value


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


def build_destination(
    src_root: Path, dst_root: Path, src_file: Path, recursive: bool
) -> Path:
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

    cmd = ["sops", sops_mode_flag, "--output", str(dst_file), str(src_file)]
    env = os.environ.copy()
    env[SOPS_ENV_KEY] = str(key_file)

    proc = subprocess.run(cmd, env=env, capture_output=True, text=True, check=False)

    if proc.returncode != 0:
        try:
            if dst_file.exists():
                dst_file.unlink()
        except OSError:
            pass
        err = (proc.stderr or "").strip() or f"sops exited with code {proc.returncode}"
        return False, err

    if chmod_600:
        try:
            os.chmod(dst_file, stat.S_IRUSR | stat.S_IWUSR)
        except OSError as exc:
            return False, f"Could not set 0600 permissions on {dst_file}: {exc}"

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
        source_dir = plain_dir
        target_dir = vault_dir
        sops_flag = "-e"
    elif mode == "decrypt":
        source_dir = vault_dir
        target_dir = plain_dir
        sops_flag = "-d"
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

    failed = 0
    processed = 0
    skipped = 0

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
    print("Choose action:")
    print("  1) Encrypt (default)")
    print("  2) Decrypt")
    while True:
        choice = input("Enter choice [1/2]: ").strip()
        if choice in ("", "1"):
            return "encrypt"
        if choice == "2":
            return "decrypt"
        print("Invalid choice. Please enter 1 or 2.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Encrypt/decrypt env files with SOPS safely."
    )
    parser.add_argument(
        "command",
        nargs="?",
        choices=("encrypt", "decrypt"),
        help="Operation mode. If omitted, interactive prompt is used when possible.",
    )
    parser.add_argument(
        "--key-file",
        default=DEFAULT_AGE_KEY_FILE,
        help="Path to AGE SSH private key file.",
    )
    parser.add_argument(
        "--plain-dir",
        default=DEFAULT_PLAIN_DIR,
        help="Directory with plaintext env files.",
    )
    parser.add_argument(
        "--vault-dir",
        default=DEFAULT_VAULT_DIR,
        help="Directory with encrypted env files.",
    )

    parser.add_argument(
        "--recursive",
        dest="recursive",
        action="store_true",
        default=None,
        help="Process directories recursively.",
    )
    parser.add_argument(
        "--no-recursive",
        dest="recursive",
        action="store_false",
        help="Disable recursive processing.",
    )

    parser.add_argument(
        "--overwrite",
        dest="overwrite",
        action="store_true",
        default=None,
        help="Overwrite existing destination files.",
    )
    parser.add_argument(
        "--no-overwrite",
        dest="overwrite",
        action="store_false",
        help="Do not overwrite existing destination files.",
    )

    parser.add_argument(
        "--chmod-600",
        dest="chmod_600",
        action="store_true",
        default=None,
        help="Set output file mode to 0600.",
    )
    parser.add_argument(
        "--no-chmod-600",
        dest="chmod_600",
        action="store_false",
        help="Do not force output file mode 0600.",
    )

    parser.add_argument(
        "-i",
        "--interactive",
        action="store_true",
        help="Force interactive menu if command is omitted.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would run without executing sops.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Verbose logs (never prints file contents).",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not check_dependency_sops():
        eprint("ERROR: `sops` not available in PATH.")
        return int(ExitCode.DEPENDENCY_MISSING)

    recursive = bool_from_args(args.recursive, DEFAULT_RECURSIVE)
    overwrite = bool_from_args(args.overwrite, DEFAULT_OVERWRITE)
    chmod_600 = bool_from_args(args.chmod_600, DEFAULT_CHMOD_600)

    key_file = Path(args.key_file).expanduser().resolve(strict=False)
    plain_dir = Path(args.plain_dir).expanduser().resolve(strict=False)
    vault_dir = Path(args.vault_dir).expanduser().resolve(strict=False)

    command = args.command
    if command is None:
        if args.interactive or sys.stdin.isatty():
            command = interactive_mode_prompt()
        else:
            eprint("ERROR: command required in non-interactive mode: encrypt|decrypt")
            return int(ExitCode.USAGE_ERROR)

    result = process_mode(
        mode=command,
        key_file=key_file,
        plain_dir=plain_dir,
        vault_dir=vault_dir,
        recursive=recursive,
        overwrite=overwrite,
        chmod_600=chmod_600,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )
    return int(result)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        eprint("Interrupted by user.")
        raise SystemExit(130)
