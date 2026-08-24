# PLAN — Omarchy across distros

**Status**: locked. Plan + docs done (`docs/`). Next phase: implementation.

## Goal

Full Omarchy flow — SUPER+SPACE menu (Install / Remove / System Update), shell/bar/Hyprland integration — on any distro running Hyprland, not just Arch.

## Architecture (locked)

- **Runtime** = git clone of the canonical repo (URL pending) as `OMARCHY_PATH` — updatable via git pull + migrations. No frozen bundle copy, **no `/usr/bin` sync** (eliminates the update-dot clobbering class of bugs).
- **State** = `omarchy-config/` + `omarchy-state/` + themes/backgrounds/plugins — user-owned, survives runtime updates.
- **install.sh** = per-distro glue: dep mapping (hyprland, quickshell build-from-source w/ guide, uwsm, sddm/alternative, gum, fonts), 7 systemd user units, `/etc/profile.d` glue, etc-overrides. Arch-only bits (PAM lock, snapper, limine, Plymouth) degrade to non-fatal notices.
- Re-applied at source and committed: omazed guard, browser-policy user-level fallback, background relative-symlink fix.

## Phase 1 — `omarchy-pm` (package backend abstraction)

- Primitives: `install | remove | search | list-installed | is-missing | update | update-all`.
- Auto-detect backend: pacman+yay | dnf | apt | flatpak. `OMARCHY_PM` env override for testing.
- Chokepoints re-pointed through it: `omarchy-pkg-add`, `omarchy-pkg-drop`, `omarchy-pkg-install`, `omarchy-install-app` / `omarchy-install-and-launch`, `omarchy-install-preinstalls` (+ ~29 other PM-touching bins).

## Phase 2 — pkgmap (user-editable, with guide)

- Single mapping file in state: `omarchy-config/pkgmap/pkgmap.conf`.
- Line format: `arch-name | dnf=foo | flatpak=com.example | apt=foo` (or `unsupported`).
- Fallback chain at runtime: distro repo → flatpak → graceful "not available".
- Covers ~40 AUR names: cursor-bin, bitwarden, minecraft-launcher, lmstudio-bin, ollama-cuda/rocm, ttf-\*-nerd, etc.

## Phase 3 — System Update (user-configurable, with guide)

- Menu section reframed as **System Update**; `omarchy-update` = runtime git pull + migrations + user-configured system update.
- State config `omarchy-config/system-update.conf`: which backends/commands run. Presets per distro (e.g. `dnf upgrade --refresh`, `flatpak update`). keyring / orphan / pkg-prune steps skipped unless configured.
- Guide: what the Arch flow did, per-distro presets, how to customize.

## Phase 4 — Menu layer

- **State override = full replacement**: `omarchy-config/omarchy-menu.jsonc` replaces the runtime copy when present.
- `omarchy-menu-diff` helper: diffs state copy vs runtime copy (usage one-liner in guide).
- `install.aur` entry rendered only when yay is present.

## Phase 5 — Verification (later)

- bwrap sandbox, stubbed package backends + `OMARCHY_PM` override, headless menu-flow tests (rig lessons: stubs-first PATH, `command -v` pre-flight, marker-free obs-home).
- Fedora VM parked — future real-distro test target.

## Deliverables — docs phase (next)

1. `pkgmap.conf` reference + per-distro worked examples guide.
2. System Update setup guide + distro presets.
3. install.sh distro-support matrix (Fedora first) + quickshell build guide.
4. Menu override + `omarchy-menu-diff` usage guide.