#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-/data/dotfiles}"
CONFIG="${CONFIG:-$HOME/.config}"

[[ -d "$DOTFILES" ]] || { echo "dotfiles dir missing: $DOTFILES"; exit 1; }
mkdir -p "$CONFIG"

for entry in "$DOTFILES"/* "$DOTFILES"/.[!.]* "$DOTFILES"/..?*; do
  [[ -e "$entry" ]] || continue
  name=$(basename "$entry")
  target="$CONFIG/$name"
  if [[ -L "$target" ]] || [[ -e "$target" ]]; then
    echo "skip (already exists): $name"
    continue
  fi
  ln -s "$entry" "$target"
  echo "linked: $name"
done
