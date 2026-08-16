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
APP_CONFIGS=0
SYSTEMD=0
CHECK_DEPS=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --force         Overwrite existing configs in place instead of backing them up
  --no-profile    Do not add OMARCHY_PATH/PATH exports to ~/.profile
  --app-configs   Also deploy Omarchy's app config templates (terminals,
                  starship, git, tmux, ...) to ~/.config/ (skips hypr/ + omarchy/)
  --systemd       Install Omarchy systemd user units (path-rewritten to this
                  bundle) and enable them
  --check-deps    Check dependencies and exit (nonzero if required deps are
                  missing); performs no deployment
  --dry-run       Print what would be done without changing anything
  --help          Show this help
EOF
}

while (($#)); do
  case "$1" in
    --force) FORCE=1 ;;
    --no-profile) PROFILE=0 ;;
    --app-configs) APP_CONFIGS=1 ;;
    --systemd) SYSTEMD=1 ;;
    --check-deps) CHECK_DEPS=1 ;;
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

check_deps() {
  local fail=0 missing_required=() found

  echo "== Dependency check =="
  echo ""
  echo "Required:"
  for cmd in hyprland uwsm uwsm-app quickshell notify-send bash; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "  [ok]  $cmd"
    else
      echo "  [!!]  $cmd NOT FOUND (required for full replication)"
      missing_required+=("$cmd")
      fail=1
    fi
  done

  if command -v hyprland >/dev/null 2>&1; then
    local hv ver maj min
    hv="$(hyprland --version 2>/dev/null | head -1)"
    ver="$(printf '%s\n' "$hv" | sed -n 's/^Hyprland \([0-9][0-9]*\.[0-9][0-9]*\)\..*/\1/p')"
    if [[ -n "$ver" ]]; then
      maj="${ver%%.*}"
      min="${ver#*.}"
      if ((maj > 0 || min >= 56)); then
        echo "  [ok]  Hyprland version $ver (>= 0.56 required)"
      else
        echo "  [!!]  Hyprland $ver is too old (>= 0.56 with Lua config support needed)"
        fail=1
      fi
    else
      echo "  [..]  Hyprland version not parseable from '$hv'"
    fi
    if [[ -f /usr/share/hypr/stubs/hl.meta.lua ]]; then
      echo "  [ok]  Lua config backend detected (/usr/share/hypr/stubs)"
    else
      echo "  [..]  Lua config backend not detected - verify Hyprland was built"
      echo "        with -DConfig_LUA=true (entry point must be hyprland.lua)"
    fi
  fi

  if systemctl --user show-environment >/dev/null 2>&1; then
    echo "  [ok]  systemd user session reachable"
  else
    echo "  [..]  systemd user session not reachable here (normal outside a login session)"
  fi

  if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    echo "  [ok]  $HOME/.config/hypr/hyprland.lua (config entry point) present"
  else
    echo "  [..]  ~/.config/hypr/hyprland.lua not present yet - run install first"
  fi

  echo ""
  echo "Common helpers (recommended):"
  found=0
  for cmd in find xargs lua; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "  [ok]  $cmd"
    else
      echo "  [..]  $cmd missing"
    fi
  done

  echo ""
  echo "Optional (powers keybindings when installed):"
  found=0
  for cmd in pamixer wpctl; do
    command -v "$cmd" >/dev/null 2>&1 && { echo "  [ok]  $cmd (audio)"; found=1; break; }
  done
  ((found)) || echo "  [..]  pamixer/wpctl missing (audio keybindings)"
  found=0
  command -v brightnessctl >/dev/null 2>&1 && { echo "  [ok]  brightnessctl (brightness)"; found=1; }
  ((found)) || echo "  [..]  brightnessctl missing (brightness keybindings)"
  found=0
  for cmd in grim slurp wl-copy; do
    command -v "$cmd" >/dev/null 2>&1 || found=1
  done
  ((found)) || echo "  [ok]  grim + slurp + wl-copy (screenshots)"
  ((found)) && echo "  [..]  grim/slurp/wl-copy incomplete (screenshot keybindings)"
  found=0
  command -v udiskie >/dev/null 2>&1 && { echo "  [ok]  udiskie (USB mounting)"; found=1; }
  ((found)) || echo "  [..]  udiskie missing (USB mounting)"
  found=0
  command -v playerctl >/dev/null 2>&1 && { echo "  [ok]  playerctl (media control)"; found=1; }
  ((found)) || echo "  [..]  playerctl missing (media keybindings)"
  found=0
  for b in firefox firefox-esr chromium chromium-browser microsoft-edge google-chrome brave-browser zen-browser librewolf xdg-open; do
    if command -v "$b" >/dev/null 2>&1; then echo "  [ok]  browser: $b"; found=1; break; fi
  done
  ((found)) || echo "  [..]  no browser found (browser keybindings)"

  echo ""
  if (( ${#missing_required[@]} > 0 )); then
    echo "MISSING REQUIRED: ${missing_required[*]}"
  else
    echo "All required dependencies present."
  fi
  return "$fail"
}

if ((CHECK_DEPS == 1)); then
  if check_deps; then
    echo ""
    echo "Dependency check PASSED."
    exit 0
  else
    echo ""
    echo "Dependency check FAILED - install the missing required packages and rerun."
    exit 1
  fi
fi

run() {
  if ((DRY_RUN)); then
    echo "  [dry] $*"
  else
    "$@"
  fi
}

deploy_dir() {
  local src="$1" dst="$2"
  if [[ -d "$dst" ]] && [[ -n "$(ls -A "$dst" 2>/dev/null)" ]] && ((FORCE == 0)); then
    local bak="$dst.bak.$(date +%Y%m%d-%H%M%S)"
    run mv "$dst" "$bak"
    [[ -d "$bak" ]] && echo "  backed up existing config to $bak"
  fi
  run mkdir -p "$dst"
  run cp -a "$src/." "$dst/"
  echo "  deployed $src -> $dst/"
}

deploy_file() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]] && ((FORCE == 0)); then
    local bak="$dst.bak.$(date +%Y%m%d-%H%M%S)"
    run mv "$dst" "$bak"
    [[ -e "$bak" ]] && echo "  backed up existing file to $bak"
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
  echo "  deployed $src -> $dst"
}

echo "Deploying core configs..."
deploy_dir "$BUNDLE_DIR/hypr"            "$HOME/.config/hypr"
deploy_dir "$BUNDLE_DIR/omarchy-config"  "$HOME/.config/omarchy"
deploy_dir "$BUNDLE_DIR/omarchy-state"   "$HOME/.local/state/omarchy"
deploy_file "$OMARCHY_PATH/default/xcompose" "$HOME/.XCompose"
deploy_dir "$OMARCHY_PATH/default/wayland-sessions" "$HOME/.local/share/wayland-sessions"

if ((APP_CONFIGS == 1)); then
  echo "Deploying app config templates..."
  for entry in "$OMARCHY_PATH"/config/*; do
    [[ -e "$entry" ]] || continue
    name="$(basename "$entry")"
    case "$name" in
      hypr|omarchy) echo "  skip $name (user-custom versions deployed above)"; continue ;;
    esac
    if [[ -d "$entry" ]]; then
      deploy_dir "$entry" "$HOME/.config/$name"
    else
      deploy_file "$entry" "$HOME/.config/$name"
    fi
  done
fi

if ((SYSTEMD == 1)); then
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "install.sh: --systemd requested but systemctl is not available" >&2
    exit 1
  fi
  UNIT_DIR="$HOME/.local/share/systemd/user"
  echo "Installing systemd user units (rewritten to use this bundle's binaries)..."
  run mkdir -p "$UNIT_DIR"
  for unit in "$OMARCHY_PATH"/default/systemd/user/*.service; do
    [[ -f "$unit" ]] || continue
    target="$UNIT_DIR/$(basename "$unit")"
    if ((DRY_RUN)); then
      echo "  [dry] rewrite + install $(basename "$unit")"
    else
      sed "s|/usr/bin/omarchy|$OMARCHY_PATH/bin/omarchy|g" "$unit" > "$target"
      echo "  installed $(basename "$unit")"
    fi
  done
  run systemctl --user daemon-reload
  for unit in "$UNIT_DIR"/omarchy-*.service "$UNIT_DIR"/bt-agent.service; do
    [[ -f "$unit" ]] || continue
    run systemctl --user enable "$(basename "$unit")"
  done
  echo "  Note: fcitx5/tailscale/bt-agent units also require those programs installed."
fi

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
if ((DRY_RUN)); then
  if check_deps; then :; fi
  echo ""
  echo "Dry run complete - nothing was changed."
  echo "Rerun without --dry-run to apply."
else
  if check_deps; then :; fi
  echo ""
  echo "Done. Log out and back in (or source ~/.profile), then start Hyprland."
  echo "Sanity checks:  hyprctl version && hyprctl configerrors && omarchy version"
fi
