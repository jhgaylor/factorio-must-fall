#!/usr/bin/env bash
# Symlink this mod source into the Factorio mods directory so the game loads it
# live (no rebuild between edits — just restart Factorio or reload the save).
#
# Factorio loads an UNZIPPED mod from a folder whose name is EXACTLY the mod
# `name` from info.json (no version suffix). We point that folder at this repo.
set -euo pipefail

MOD_NAME="factorio-must-fall"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODS_DIR="$HOME/Library/Application Support/factorio/mods"   # macOS
LINK="$MODS_DIR/$MOD_NAME"

if [[ ! -d "$MODS_DIR" ]]; then
    echo "Factorio mods dir not found: $MODS_DIR" >&2
    exit 1
fi

if [[ -e "$LINK" && ! -L "$LINK" ]]; then
    echo "Refusing to overwrite non-symlink at: $LINK" >&2
    exit 1
fi

ln -sfn "$SRC" "$LINK"
echo "Linked: $LINK -> $SRC"
echo "Restart Factorio (or reload the save) to pick up changes."
