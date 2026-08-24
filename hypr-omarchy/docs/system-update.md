# System Update

Part of the cross-distro rework (see `PLAN.md`). Once the rework lands, the menu's **Update → System Update** action runs *your* system update — defined by you, in state config, with per-distro presets.

## What it replaces

On Arch, `omarchy-update` did everything:

1. Update Omarchy itself (git pull + migrations)
2. Refresh the package keyring
3. System upgrade (`pacman -Syu`)
4. Remove orphaned packages
5. Prune old package cache

Steps 2–5 are Arch-specific. On other distros they either don't exist (`keyring`, `pkg-prune`) or have different commands (`dnf upgrade --refresh`, `apt update && apt upgrade`, `flatpak update`). The rework keeps step 1 (distro-agnostic) and makes steps 2–5 your choice.

## Location

User-editable, in your state config:

```
omarchy-config/system-update.conf
```

## Format

One step per line, executed in order. `#` starts a comment. `!` prefixed lines are always skipped unless explicitly un-commented (the Arch-only steps).

```ini
# omarchy-config/system-update.conf
# Each line is a command run as your user (sudo is fine inside).
# Empty file = Omarchy updates only, no system update.

# --- Preset: Fedora (dnf + flatpak) ---
dnf upgrade --refresh
flatpak update -y

# --- Arch-only steps, disabled by default ---
# !pacman -Syu --noconfirm
# !omarchy-update-keyring
# !omarchy-pkg-orphan-remove
# !omarchy-pkg-prune
```

## Presets

Pick one and paste it in — or use your own.

### Fedora (dnf + optional flatpak)

```ini
dnf upgrade --refresh
flatpak update -y
```

### Debian / Ubuntu (apt)

```ini
sudo apt update
sudo apt upgrade -y
flatpak update -y
```

### Arch (the original behavior)

```ini
omarchy-update-keyring
omarchy-update-system-pkgs
omarchy-update-aur-pkgs
omarchy-update-orphan-pkgs
omarchy-update-pkg-prune
```

### No system update

Empty file (or only comments) → `omarchy-update` updates Omarchy itself and stops there.

## What `omarchy-update` runs, in order

1. Update Omarchy: git pull + migrations (always)
2. Run every line in `system-update.conf` (your system update)
3. Report: what updated, what was skipped

A failing line stops the update and shows the error in the presentation terminal — same behavior as the Arch flow.

## Customizing

- **Multiple backends**: dnf and flatpak in the same file is fine (Fedora example above) — they're just commands.
- **Order matters**: put repo refresh (`dnf upgrade --refresh`) before flatpak if you want distro packages to win on conflicts — usually you do.
- **Conditional steps**: the file is plain shell-ish lines, so `which flatpak >/dev/null && flatpak update -y` works if you want flatpak updates only when flatpak is installed.
- **Verification**: after editing, run `omarchy-update` in a terminal (or the menu's System Update entry) and watch the presentation output.

## Troubleshooting

- "System Update ran but nothing happened" → file is empty/commented; add steps.
- Command not found (`dnf` on Ubuntu) → wrong preset; use the one for your distro.
- Update stopped midway → the failing step's output is shown in the terminal; fix that line and rerun (steps are not partially retried).