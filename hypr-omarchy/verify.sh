#!/bin/bash

# Omarchy cross-distro rework verification harness.
#
# Runs the stub-backed test suites headless, with zero risk to the real
# system: every mutating binary (dnf, rpm, flatpak, sudo, yay, pacman) is a
# recording stub, the HOME is a disposable fake, and OMARCHY_PM forces the
# dnf backend. No bwrap needed — there is nothing to contain.
#
#   verify.sh            run all suites (P1 pm/pkgs, P1b backend matrix, P3 system-update, P4 menu)
#   verify.sh --menu     only the menu logic suite (requires node)
#   verify.sh --pm       only the package manager suite
#   verify.sh --backends only the apt/pacman/flatpak backend matrix
#   verify.sh --update   only the system-update suite

set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BIN="$ROOT/omarchy/bin"
WORK=$(mktemp -d "/tmp/omarchy-verify.XXXXXX")
STUBS="$WORK/stubs"
STATE="$WORK/state"
HOMEDIR="$WORK/home"
export OMARCHY_TEST_STATE="$STATE"

trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
FAILED_DESCS=()

preflight() {
  local missing=0 cmd
  for cmd in bash grep sed diff tr xargs cat mkdir rm printf; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "missing: $cmd"; missing=1; }
  done
  return "$missing"
}

# --- stubs ---------------------------------------------------------------

write_stubs() {
  mkdir -p "$STUBS" "$STATE/installed" "$STATE/flatpaks" "$STATE/repo" \
    "$HOMEDIR/.config/omarchy/pkgmap"

  cat >"$STUBS/lib.sh" <<'EOF'
STATE_DIR=${OMARCHY_TEST_STATE:?}
LOG="$STATE_DIR/calls.log"
log() { echo "$*" >>"$LOG"; }
EOF

  cat >"$STUBS/rpm" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "rpm $*"
case "$1" in
  -q) [[ -f "$STATE_DIR/installed/$2" ]] ;;
  -qa) ls "$STATE_DIR/installed" ;;
esac
EOF

  cat >"$STUBS/dnf" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "dnf $*"
[[ "$1" == "repoquery" ]] && { ls "$STATE_DIR/installed"; exit 0; }
if [[ "$1" == "install" ]]; then
  shift
  bad=0
  for p in "$@"; do
    [[ $p == -* ]] && continue
    if [[ -f "$STATE_DIR/repo/$p" ]]; then touch "$STATE_DIR/installed/$p"
    else echo "Error: Unable to find a match: $p" >&2; bad=1; fi
  done
  exit $bad
fi
if [[ "$1" == "remove" ]]; then
  shift
  for p in "$@"; do
    [[ $p == -* ]] && continue
    rm -f "$STATE_DIR/installed/$p"
  done
  exit 0
fi
if [[ "$1" == "upgrade" || "$1" == "info" || "$1" == "search" ]]; then exit 0; fi
exit 1
EOF

  cat >"$STUBS/flatpak" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "flatpak $*"
if [[ "$1" == "install" ]]; then
  shift 2
  for p in "$@"; do touch "$STATE_DIR/flatpaks/$p"; done
  exit 0
fi
if [[ "$1" == "uninstall" ]]; then
  shift 3
  for p in "$@"; do rm -f "$STATE_DIR/flatpaks/$p"; done
  exit 0
fi
if [[ "$1" == "info" ]]; then [[ -f "$STATE_DIR/flatpaks/$2" ]]; exit; fi
if [[ "$1" == "update" || "$1" == "search" ]]; then exit 0; fi
if [[ "$1" == "list" ]]; then shift; ls "$STATE_DIR/flatpaks" 2>/dev/null; exit 0; fi
exit 1
EOF

  cat >"$STUBS/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF

  cat >"$STUBS/apt-get" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "apt-get $*"
if [[ "$1" == "install" ]]; then
  shift
  bad=0
  for p in "$@"; do
    [[ $p == -* ]] && continue
    if [[ -f "$STATE_DIR/repo/$p" ]]; then touch "$STATE_DIR/installed/$p"
    else echo "E: Unable to locate package $p" >&2; bad=1; fi
  done
  exit $bad
fi
if [[ "$1" == "remove" ]]; then
  shift
  for p in "$@"; do [[ $p == -* ]] && continue; rm -f "$STATE_DIR/installed/$p"; done
  exit 0
fi
if [[ "$1" == "upgrade" || "$1" == "update" ]]; then exit 0; fi
exit 1
EOF

  cat >"$STUBS/dpkg" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "dpkg $*"
if [[ "$1" == "-s" ]]; then [[ -f "$STATE_DIR/installed/$2" ]]; exit; fi
exit 1
EOF

  cat >"$STUBS/pacman" <<'EOF'
#!/bin/bash
source "$(dirname "$0")/lib.sh"
log "pacman $*"
case "$1" in
  -Q|-Qi) [[ -f "$STATE_DIR/installed/$2" ]] ;;
  -S) shift; bad=0
      for p in "$@"; do
        [[ $p == -* ]] && continue
        if [[ -f "$STATE_DIR/repo/$p" ]]; then touch "$STATE_DIR/installed/$p"
        else echo "error: target not found: $p" >&2; bad=1; fi
      done
      exit $bad ;;
  -R) shift; for p in "$@"; do [[ $p == -* ]] && continue; rm -f "$STATE_DIR/installed/$p"; done; exit 0 ;;
  -Syu|-Sy) exit 0 ;;
esac
exit $?
EOF

  chmod +x "$STUBS"/*

  cp "$ROOT/omarchy-config/pkgmap/pkgmap.conf" "$HOMEDIR/.config/omarchy/pkgmap/pkgmap.conf"
  for p in cursor steam ollama code cascadia-code-fonts firefox spotify tailscale; do
    touch "$STATE/repo/$p"
  done
}

# --- test helpers ---------------------------------------------------------

t() {
  local desc="$1" want="$2"
  shift 2
  if "$@" >/dev/null 2>&1; then got=0; else got=1; fi
  if [[ $got == "$want" ]]; then
    PASS=$((PASS + 1)); echo "PASS  $desc"
  else
    FAIL=$((FAIL + 1)); FAILED_DESCS+=("$desc (exit=$got want=$want)"); echo "FAIL  $desc (exit=$got want=$want)"
  fi
}

expect() { # expect <desc> <expected-text> <actual-text>
  local desc="$1" want="$2" got="$3"
  if [[ $got == "$want" ]]; then
    PASS=$((PASS + 1)); echo "PASS  $desc ($got)"
  else
    FAIL=$((FAIL + 1)); FAILED_DESCS+=("$desc (got '$got' want '$want')"); echo "FAIL  $desc (got '$got' want '$want')"
  fi
}

expect_contains() { # expect_contains <desc> <needle> <haystack>
  local desc="$1" needle="$2" hay="$3"
  if [[ $hay == *"$needle"* ]]; then
    PASS=$((PASS + 1)); echo "PASS  $desc"
  else
    FAIL=$((FAIL + 1)); FAILED_DESCS+=("$desc (missing '$needle')"); echo "FAIL  $desc (missing '$needle')"
  fi
}

reset_state() {
  rm -f "$STATE/calls.log"
  rm -f "$STATE/installed/"* "$STATE/flatpaks/"*
}

# --- P1: omarchy-pm + package chokepoints ---------------------------------

suite_pm() {
  echo "=== P1: omarchy-pm (backend detect, resolve, install/remove/update) ==="
  reset_state

  expect "backend forced by OMARCHY_PM" dnf "$(omarchy-pm backend)"
  expect "resolve pkgmap dnf target" "cursor-bin -> cursor" "$(omarchy-pm resolve cursor-bin)"
  expect "resolve flatpak fallback" "lmstudio-bin -> flatpak:ai.lmstudio.LMStudio" "$(omarchy-pm resolve lmstudio-bin)"
  expect "resolve unsupported" "ttf-meslo-nerd -> unsupported" "$(omarchy-pm resolve ttf-meslo-nerd)"
  expect "resolve passthrough" "git -> git" "$(omarchy-pm resolve git)"

  t "pkg-missing unknown -> missing" 0 omarchy-pkg-missing nope-does-not-exist
  t "pkg-present unknown -> fail" 1 omarchy-pkg-present nope-does-not-exist
  t "pkg-missing unsupported -> missing" 0 omarchy-pkg-missing ttf-meslo-nerd
  t "pkg-present unsupported -> fail" 1 omarchy-pkg-present ttf-meslo-nerd

  t "pkg-add cursor-bin steam" 0 omarchy-pkg-add cursor-bin steam
  [[ -f "$STATE/installed/cursor" && -f "$STATE/installed/steam" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  dnf installed cursor+steam"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("dnf installs"); echo "FAIL  dnf installs"; }

  t "pkg-add again -> idempotent gate" 0 omarchy-pkg-add cursor-bin steam
  n=$(grep -c "^dnf install" "$STATE/calls.log")
  [[ $n == 1 ]] && { PASS=$((PASS + 1)); echo "PASS  second pkg-add skipped dnf (calls=$n)"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("gate skip calls=$n"); echo "FAIL  gate skip (calls=$n)"; }

  t "pkg-add flatpak fallback (lmstudio)" 0 omarchy-pkg-add lmstudio-bin
  [[ -f "$STATE/flatpaks/ai.lmstudio.LMStudio" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  flatpak install"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("flatpak install"); echo "FAIL  flatpak install"; }

  t "pkg-add unsupported -> 1" 1 omarchy-pkg-add grok-bot
  t "pkg-add bogus passthrough -> 1" 1 omarchy-pkg-add totally-not-real
  t "pkg-add mixed good+unsupported -> 1" 1 omarchy-pkg-add steam grok-bot
  t "pkg-add font via pkgmap" 0 omarchy-pkg-add ttf-cascadia-mono-nerd
  [[ -f "$STATE/installed/cascadia-code-fonts" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  font translated to cascadia-code-fonts"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("font translation"); echo "FAIL  font translation"; }

  t "pkg-drop steam" 0 omarchy-pkg-drop steam
  [[ ! -f "$STATE/installed/steam" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  steam removed"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("steam removed"); echo "FAIL  steam removed"; }
  t "pkg-drop not-installed -> ignored" 0 omarchy-pkg-drop ghost-pkg
  t "pkg-drop flatpak-mapped" 0 omarchy-pkg-drop lmstudio-bin

  t "pm update" 0 omarchy-pm update
  grep -q "^dnf upgrade --refresh -y" "$STATE/calls.log" \
    && { PASS=$((PASS + 1)); echo "PASS  update cmd"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("update cmd"); echo "FAIL  update cmd"; }
  t "pm update-all" 0 omarchy-pm update-all
  grep -q "^flatpak update -y" "$STATE/calls.log" \
    && { PASS=$((PASS + 1)); echo "PASS  update-all flatpak"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("update-all flatpak"); echo "FAIL  update-all flatpak"; }
  t "pm search" 0 omarchy-pm search foo
  t "pm list-installed" 0 omarchy-pm list-installed

  t "AUR add guarded without yay" 1 env PATH="$STUBS:$BIN" omarchy-pkg-aur-add cursor-bin
  t "AUR TUI guarded without yay" 1 env PATH="$STUBS:$BIN" omarchy-pkg-aur-install
}

# --- backend matrix: apt / pacman / flatpak backends ----------------------

suite_backends() {
  echo
  echo "=== P1b: backend matrix (apt, pacman, flatpak) ==="

  reset_state
  export OMARCHY_PM=apt
  expect "apt backend detected" apt "$(omarchy-pm backend)"
  expect "apt: dnf-only entry -> flatpak fallback" "bitwarden -> flatpak:com.bitwarden.desktop" "$(omarchy-pm resolve bitwarden)"
  expect "apt: dnf-only entry -> unavailable" "cursor-bin -> unavailable" "$(omarchy-pm resolve cursor-bin)"
  expect "apt: unsupported" "grok-bot -> unsupported" "$(omarchy-pm resolve grok-bot)"
  t "apt: install cursor via apt target" 0 omarchy-pkg-add cursor-bin
  [[ -f "$STATE/installed/cursor" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  apt installed cursor"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("apt install"); echo "FAIL  apt install"; }
  t "apt: flatpak fallback install" 0 omarchy-pkg-add bitwarden
  [[ -f "$STATE/flatpaks/com.bitwarden.desktop" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  apt->flatpak fallback installed"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("apt->flatpak fallback"); echo "FAIL  apt->flatpak fallback"; }
  t "apt: font translation" 0 omarchy-pkg-add ttf-cascadia-mono-nerd
  t "apt: remove" 0 omarchy-pkg-drop steam

  reset_state
  export OMARCHY_PM=pacman
  expect "pacman backend detected" pacman "$(omarchy-pm backend)"
  expect "pacman: no pacman column -> flatpak fallback" "steam -> flatpak:com.valvesoftware.Steam" "$(omarchy-pm resolve steam)"
  expect "pacman: passthrough (no line)" "git -> git" "$(omarchy-pm resolve git)"
  expect "pacman: entry w/o pacman column" "cursor-bin -> unavailable" "$(omarchy-pm resolve cursor-bin)"
  t "pacman: flatpak fallback install" 0 omarchy-pkg-add steam
  [[ -f "$STATE/flatpaks/com.valvesoftware.Steam" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  pacman->flatpak fallback installed"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("pacman->flatpak fallback"); echo "FAIL  pacman->flatpak fallback"; }
  t "pacman: bogus -> 1" 1 omarchy-pkg-add totally-not-real

  reset_state
  export OMARCHY_PM=flatpak
  expect "flatpak backend detected" flatpak "$(omarchy-pm backend)"
  expect "flatpak: native app-id target" "lmstudio-bin -> flatpak:ai.lmstudio.LMStudio" "$(omarchy-pm resolve lmstudio-bin)"
  expect "flatpak: entry without flatpak column" "cursor-bin -> unavailable" "$(omarchy-pm resolve cursor-bin)"
  expect "flatpak: passthrough" "git -> git" "$(omarchy-pm resolve git)"
  t "flatpak: install app-id" 0 omarchy-pkg-add lmstudio-bin
  [[ -f "$STATE/flatpaks/ai.lmstudio.LMStudio" ]] \
    && { PASS=$((PASS + 1)); echo "PASS  flatpak-only install"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("flatpak-only install"); echo "FAIL  flatpak-only install"; }
  t "flatpak: drop app-id" 0 omarchy-pkg-drop lmstudio-bin

  export OMARCHY_PM=dnf
}

# --- P3: system-update.conf runner ---------------------------------------

suite_update() {
  echo
  echo "=== P3: omarchy-system-update (user-configured System Update) ==="
  local conf="$HOMEDIR/.config/omarchy/system-update.conf"
  reset_state

  rm -f "$conf"
  t "absent conf -> exit 0" 0 omarchy-system-update
  expect_contains "absent conf message" \
    "No system-update.conf found; skipping system update" \
    "$(omarchy-system-update)"

  printf '# nothing\n\n# still nothing\n' >"$conf"
  t "empty conf -> exit 0" 0 omarchy-system-update
  expect_contains "empty conf message" \
    "No system update steps configured (empty system-update.conf)" \
    "$(omarchy-system-update)"

  cat >"$conf" <<'EOF'
# comment line
dnf upgrade --refresh
!pacman -Syu --noconfirm
!omarchy-update-keyring
flatpak update -y
EOF
  reset_state
  t "fedora preset -> exit 0" 0 omarchy-system-update
  grep -q "^dnf upgrade --refresh" "$STATE/calls.log" \
    && { PASS=$((PASS + 1)); echo "PASS  dnf step ran"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("dnf step"); echo "FAIL  dnf step"; }
  grep -q "^flatpak update -y" "$STATE/calls.log" \
    && { PASS=$((PASS + 1)); echo "PASS  flatpak step ran"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("flatpak step"); echo "FAIL  flatpak step"; }
  grep -qE "pacman|keyring" "$STATE/calls.log" \
    && { FAIL=$((FAIL + 1)); FAILED_DESCS+=("disabled steps ran"); echo "FAIL  disabled '!' steps ran"; } \
    || { PASS=$((PASS + 1)); echo "PASS  disabled '!' steps skipped"; }

  cat >"$conf" <<'EOF'
which flatpak >/dev/null && flatpak update -y
EOF
  reset_state
  t "conditional shell line -> exit 0" 0 omarchy-system-update
  grep -q "^flatpak update -y" "$STATE/calls.log" \
    && { PASS=$((PASS + 1)); echo "PASS  conditional executed"; } \
    || { FAIL=$((FAIL + 1)); FAILED_DESCS+=("conditional"); echo "FAIL  conditional"; }

  cat >"$conf" <<'EOF'
dnf upgrade --refresh
false
dnf install cursor
EOF
  reset_state
  t "failing step -> exit 1" 1 omarchy-system-update
  grep -q "dnf install" "$STATE/calls.log" \
    && { FAIL=$((FAIL + 1)); FAILED_DESCS+=("ran past failure"); echo "FAIL  steps ran past failure"; } \
    || { PASS=$((PASS + 1)); echo "PASS  stopped at failing step"; }

  rm -f "$conf"
}

# --- P4: menu logic (MenuModel.js, requires node) -------------------------

suite_menu() {
  echo
  echo "=== P4: menu logic (when guards, jsonc parse, merge) ==="
  command -v node >/dev/null 2>&1 || {
    echo "SKIP  menu suite: node not found"
    return 0
  }

  cat >"$WORK/menu-test.js" <<'EOF'
const { guardScript, parseMenuJsonc, mergeMenuSources } =
  require(process.argv[2] + "/MenuModel.js")
const fs = require("fs")
const { execSync } = require("child_process")

const ok = (d, c) => { if (!c) { console.log("FAIL  " + d); process.exitCode = 1 } else console.log("PASS  " + d) }
const runScript = (s) => {
  fs.writeFileSync(process.argv[3] + "/guard.sh", s)
  return execSync("bash " + process.argv[3] + "/guard.sh").toString().trim()
}

const items = { "install.aur": { id: "install.aur", when: "command -v no-such-tool-xyz" } }
const script = guardScript(items)
ok("guardScript emits when line",
  /if \{ command -v no-such-tool-xyz; \} >\/dev\/null 2>&1; then echo install\.aur:w:1; else echo install\.aur:w:0; fi/.test(script))
ok("when:tool absent -> :0", runScript(script).includes("install.aur:w:0"))
items["install.aur"].when = "command -v bash"
ok("when:tool present -> :1", runScript(guardScript(items)).includes("install.aur:w:1"))

const def = parseMenuJsonc(fs.readFileSync(process.argv[4], "utf8"))
const byId = {}
for (const it of def) byId[it.id] = it
ok("default jsonc parses", Array.isArray(def) && def.length >= 261)
ok("install.aur has when guard", byId["install.aur"].when === "command -v yay")

const user = [
  { id: "install.aur", label: "overridden", when: "false" },
  { id: "my.custom", label: "My App", action: "my-app" }
]
const merged = mergeMenuSources(def, user)
ok("extension overrides same id", merged.items["install.aur"].label === "overridden")
ok("extension adds new id", merged.items["my.custom"].action === "my-app")
ok("default ids survive merge", !!merged.items["update.omarchy"])
EOF

  node "$WORK/menu-test.js" \
    "$ROOT/omarchy/shell/plugins/menu" \
    "$WORK" \
    "$ROOT/omarchy/default/omarchy/omarchy-menu.jsonc"
}

# --- main ----------------------------------------------------------------

preflight || { echo "verify.sh: missing required commands" >&2; exit 1; }
write_stubs

export PATH="$STUBS:$BIN:$PATH"
export HOME="$HOMEDIR"
export OMARCHY_PM=dnf

RUN_ALL=1
case "${1-}" in
  --pm) RUN_ALL=0; suite_pm ;;
  --backends) RUN_ALL=0; suite_backends ;;
  --update) RUN_ALL=0; suite_update ;;
  --menu) RUN_ALL=0; suite_menu ;;
  "") ;;
  *) echo "verify.sh: unknown option: $1" >&2; exit 1 ;;
esac
if [[ $RUN_ALL == 1 ]]; then
  suite_pm
  suite_backends
  suite_update
  suite_menu
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
if (( FAIL > 0 )); then
  printf 'Failed: %s\n' "${FAILED_DESCS[@]}"
  exit 1
fi
exit 0