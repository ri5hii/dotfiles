#!/bin/bash
set -euo pipefail

# Omarchy Hyprland replication bundle updater.
# Refreshes this bundle from the live device it runs on. Device-aware: each
# source is updated only when present; missing sources are reported and skipped.

BUNDLE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_PATH="$BUNDLE_DIR/omarchy"
LOG_FILE="$BUNDLE_DIR/update-dot.log"
DRY_RUN=0
PRUNE=0
LOG=1
results=()

usage() {
  cat <<'EOF'
Usage: update-dot.sh [options]

Options:
  --dry-run   Preview what would be copied/changed without writing anything
  --prune     Mirror sources (--delete): drop bundle files no longer in source
  --no-log    Do not write update-dot.log
  --help      Show this help
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --prune) PRUNE=1 ;;
    --no-log) LOG=0 ;;
    --help) usage; exit 0 ;;
    *) echo "update-dot.sh: unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

[[ -d "$OMARCHY_PATH" ]] || { echo "update-dot.sh: bundle omarchy/ missing at $OMARCHY_PATH" >&2; exit 1; }

TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

# ---- rendering ----------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_CYAN=$'\e[36m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'; C_RED=$'\e[31m'
else
  C_RESET=; C_BOLD=; C_DIM=; C_CYAN=; C_GREEN=; C_YELLOW=; C_RED=
fi

now() { date '+%H:%M:%S'; }

# out <colored> <plain> -- colored line to the terminal, plain+timestamp to the log
out() {
  local colored="$1" plain="${2:-$1}"
  if [[ -n "$plain" ]]; then
    printf '%s\n' "$colored"
    ((LOG)) && printf '[%s] %s\n' "$(now)" "$plain" >>"$LOG_FILE"
  else
    printf '\n'
    ((LOG)) && printf '\n' >>"$LOG_FILE"
  fi
}

color_for() {
  case "$1" in
    ok) printf '%s' "$C_GREEN" ;;
    skip) printf '%s' "$C_YELLOW" ;;
    planned) printf '%s' "$C_CYAN" ;;
    error) printf '%s' "$C_RED" ;;
    header) printf '%s' "$C_BOLD$C_CYAN" ;;
    info) printf '%s' "$C_CYAN" ;;
    dim) printf '%s' "$C_DIM" ;;
    *) printf '%s' "$C_RESET" ;;
  esac
}

live() {  # live <kind> <message...>
  local kind="$1"; shift
  local c; c="$(color_for "$kind")"
  out "${c}${*}${C_RESET}" "$*"
}

blank() { out "" ""; }

header() {  # header <message...>
  out "$C_BOLD$C_CYAN── $* ──$C_RESET" "── $* ──"
}

pad_trunc() {  # pad_trunc <text> <width> -- left-align to width, truncate with ellipsis
  local t="$1" w="$2"
  if ((${#t} > w)); then
    printf '%s…' "${t:0:w-1}"
  else
    printf '%-*s' "$w" "$t"
  fi
}

render_row() {  # render_row <label> <status> <detail> <elapsed>
  local label="$1" status="$2" detail="$3" elapsed="$4"
  label="$(pad_trunc "$label" 18)"
  local c; c="$(color_for "$status")"
  local padded; padded="$(printf '%-26s' "$detail")"
  out "$(printf '%-18s %s%-7s%s %s %6s' "$label" "$c" "$status" "$C_RESET" "$C_DIM$padded$C_RESET" "$elapsed")" \
      "$(printf '%-18s %-7s %-26s %6s' "$label" "$status" "$detail" "$elapsed")"
}

result_row() {  # result_row <label> <status> <detail> [elapsed]
  local label="$1" status="$2" detail="$3" elapsed="${4:-}"
  results+=("$label|$status|$detail|$elapsed")
  render_row "$label" "$status" "$detail" "$elapsed"
}

elapsed_s() {  # elapsed_s <start_ns>
  local ms=$(( ($(date +%s%N) - $1) / 1000000 ))
  printf '%d.%ds' $((ms / 1000)) $(((ms % 1000) / 100))
}

((LOG)) && : >"$LOG_FILE"

# ---- sources ------------------------------------------------------------
sync_dir() {
  local src="$1" dst="$2" label="$3"; shift 3
  local flags=(-ai) rc=0 add=0 mod=0 del=0 n line t0 elapsed
  ((PRUNE)) && flags+=(--delete)
  flags+=("$@")
  header "UPDATE $label <- $src"
  : >"$TMP_OUT"
  t0="$(date +%s%N)"
  rsync "${flags[@]}" "$src" "$dst" >"$TMP_OUT" 2>&1 || rc=$?
  elapsed="$(elapsed_s "$t0")"
  while IFS= read -r line; do
    [[ $line =~ ^(\*deleting|[>.<ch][fdL]|c[dl]) ]] || continue
    case "$line" in
      *deleting*) del=$((del + 1)) ;;
      *+++++++++*) add=$((add + 1)) ;;
      *) mod=$((mod + 1)) ;;
    esac
  done <"$TMP_OUT"
  n=$((add + mod + del))
  if ((rc != 0)); then
    result_row "$label" "error" "rsync exit $rc" "$elapsed"
  elif ((n == 0)); then
    result_row "$label" "ok" "no changes" "$elapsed"
  else
    result_row "$label" "ok" "+$add ~$mod -$del" "$elapsed"
  fi
}

update_bin() {
  local dest="$OMARCHY_PATH/bin" bins=() n=0 src t0 elapsed
  while IFS= read -r src; do bins+=("$src"); done \
    < <(ls -d /usr/bin/omarchy /usr/bin/omarchy-* 2>/dev/null || true)
  [[ -f /usr/bin/hyprland-preview-share-picker ]] && bins+=(/usr/bin/hyprland-preview-share-picker)
  (( ${#bins[@]} > 0 )) || return 1
  if ((DRY_RUN)); then
    header "UPDATE bin/ <- /usr/bin (dry-run: rebuild dir from ${#bins[@]} real files)"
    result_row "bin/" "planned" "rebuild ${#bins[@]} binaries"
    return 0
  fi
  header "UPDATE bin/ <- /usr/bin (rebuild dir from ${#bins[@]} real files)"
  t0="$(date +%s%N)"
  rm -rf "$dest"
  mkdir -p "$dest"
  for src in "${bins[@]}"; do cp -a "$src" "$dest/"; n=$((n + 1)); done
  elapsed="$(elapsed_s "$t0")"
  result_row "bin/" "ok" "$n binaries copied" "$elapsed"
}

live "info" "update-dot: refreshing bundle from $(hostname) [$(date '+%Y-%m-%d %H:%M:%S')]"
live "dim" "bundle:  $BUNDLE_DIR"
live "dim" "flags:   dry-run=$([ "$DRY_RUN" = 1 ] && echo yes || echo no)  prune=$([ "$PRUNE" = 1 ] && echo yes || echo no)"
blank

if [[ -d /usr/share/omarchy ]]; then
  sync_dir "/usr/share/omarchy/" "$OMARCHY_PATH/" "omarchy/" --exclude=bin/
else
  header "SKIP omarchy/"
  result_row "omarchy/" "skip" "no /usr/share/omarchy (not an Omarchy device)"
fi

if compgen -G '/usr/bin/omarchy' >/dev/null 2>&1 || compgen -G '/usr/bin/omarchy-*' >/dev/null 2>&1; then
  update_bin
else
  header "SKIP bin/"
  result_row "bin/" "skip" "no /usr/bin/omarchy* binaries on this device"
fi

if [[ -d "$HOME/.config/hypr" ]]; then
  sync_dir "$HOME/.config/hypr/" "$BUNDLE_DIR/hypr/" "hypr/"
else
  header "SKIP hypr/"
  result_row "hypr/" "skip" "no ~/.config/hypr"
fi

if [[ -d "$HOME/.config/omarchy" ]]; then
  sync_dir "$HOME/.config/omarchy/" "$BUNDLE_DIR/omarchy-config/" "omarchy-config/"
else
  header "SKIP omarchy-config/"
  result_row "omarchy-config/" "skip" "no ~/.config/omarchy"
fi

if [[ -d "$HOME/.local/state/omarchy/current" && -d "$HOME/.local/state/omarchy/toggles" ]]; then
  sync_dir "$HOME/.local/state/omarchy/current/" "$BUNDLE_DIR/omarchy-state/current/" "omarchy-state/current/" -L
  sync_dir "$HOME/.local/state/omarchy/toggles/" "$BUNDLE_DIR/omarchy-state/toggles/" "omarchy-state/toggles/" -L
else
  header "SKIP omarchy-state/"
  result_row "omarchy-state/" "skip" "no ~/.local/state/omarchy/{current,toggles}"
fi

# ---- report -------------------------------------------------------------
blank
out "$C_BOLD$C_CYAN═══ FINAL REPORT ═══$C_RESET" "===== FINAL REPORT ====="
out "$(printf '%-18s %-7s %-26s %6s' 'source' 'status' 'changes' 'time')" \
    "$(printf '%-18s %-7s %-26s %6s' 'source' 'status' 'changes' 'time')"
for row in "${results[@]}"; do
  IFS='|' read -r label status detail elapsed <<<"$row"
  render_row "$label" "$status" "$detail" "$elapsed"
done
blank

if ((DRY_RUN)); then
  live "dim" "Preview only -- nothing was written. Rerun without --dry-run to apply."
else
  live "dim" "Bundle updated at $(date '+%Y-%m-%d %H:%M:%S'). Review with git, then commit."
fi

if top="$(git -C "$BUNDLE_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  rel="${BUNDLE_DIR#"$top"/}"
  header "git status (repo: $top)"
  while IFS= read -r line; do
    out "$C_DIM$line$C_RESET" "$line"
  done < <(git -C "$top" status --short -- "$rel" 2>/dev/null)
fi
((LOG)) && live "dim" "log written: $LOG_FILE"
