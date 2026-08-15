#!/bin/bash
set -euo pipefail

# Omarchy Hyprland replication bundle installer.
# Deploys this bundle to ~/.config/hypr, ~/.config/omarchy and
# ~/.local/state/omarchy, and points OMARCHY_PATH at the bundle.

BUNDLE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_PATH="$BUNDLE_DIR/omarchy"
FORCE=0
DRY_RUN=0
PROFILE=1

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --force        Overwrite existing configs in place instead of backing them up
  --no-profile   Do not add OMARCHY_PATH/PATH exports to ~/.profile
  --dry-run      Print what would be done without changing anything
  --help         Show this help
EOF
}

while (($#)); do
  case "$1" in
    --force) FORCE=1 ;;
    --no-profile) PROFILE=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --help) usage; exit 0 ;;
    *) echo "install.sh: unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

for sub in omarchy hypr omarchy-config omarchy-state; do
  [[ -d "$BUNDLE_DIR/$sub" ]] || {
    echo "install.sh: missing bundle directory: $BUNDLE_DIR/$sub" >&2
    exit 1
  }
done

echo "Bundle:  $BUNDLE_DIR"
echo "OMARCHY_PATH: $OMARCHY_PATH"

deploy() {
  local src="$1" dst="$2"
  if [[ -d "$dst" ]] && [[ -n "$(ls -A "$dst" 2>/dev/null)" ]] && ((FORCE == 0)); then
    local bak="$dst.bak.$(date +%Y%m%d-%H%M%S)"
    if ((DRY_RUN)); then
      echo "  mv $dst -> $bak"
    else
      mv "$dst" "$bak"
      echo "  backed up existing config to $bak"
    fi
  fi
  if ((DRY_RUN)); then
    echo "  cp -a $src/. -> $dst/"
  else
    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
    echo "  deployed $src -> $dst/"
  fi
}

echo "Deploying configs..."
deploy "$BUNDLE_DIR/hypr"            "$HOME/.config/hypr"
deploy "$BUNDLE_DIR/omarchy-config"  "$HOME/.config/omarchy"
deploy "$BUNDLE_DIR/omarchy-state"   "$HOME/.local/state/omarchy"

if ((PROFILE == 1)); then
  PROFILE_FILE="$HOME/.profile"
  MARKER="# >>> omarchy replication bundle >>>"
  if ((DRY_RUN)); then
    echo "Profile: would add OMARCHY_PATH + PATH exports to $PROFILE_FILE"
  elif grep -qF -- "$MARKER" "$PROFILE_FILE" 2>/dev/null; then
    echo "Profile: $PROFILE_FILE already configured, skipping"
  else
    {
      echo ""
      echo "$MARKER"
      printf 'export OMARCHY_PATH="%s"\n' "$OMARCHY_PATH"
      printf 'export PATH="$OMARCHY_PATH/bin:$PATH"\n'
      echo "# <<< omarchy replication bundle <<<"
    } >>"$PROFILE_FILE"
    echo "Profile: added OMARCHY_PATH + PATH exports to $PROFILE_FILE"
  fi
fi

if ((DRY_RUN == 0)); then
  export OMARCHY_PATH
  export PATH="$OMARCHY_PATH/bin:$PATH"
fi

echo ""
echo "Prerequisite check (informational):"
for cmd in hyprland lua uwsm uwsm-app quickshell notify-send; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  [ok]  $cmd"
  else
    echo "  [!!]  $cmd NOT FOUND (required for full replication)"
  fi
done

echo ""
if ((DRY_RUN)); then
  echo "Dry run complete - nothing was changed."
  echo "Rerun without --dry-run to apply."
else
  echo "Done. Log out and back in (or source ~/.profile), then start Hyprland."
  echo "Sanity checks:  hyprctl version && hyprctl configerrors && omarchy version"
fi
