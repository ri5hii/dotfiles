# Omarchy Hyprland Replication Bundle

Self-contained replica of an [Omarchy](https://omarchy.org/) Hyprland setup for
near one-to-one replication on any other Linux distro. The Lua-based Hyprland
config, the current theme, the shell config, and every `omarchy-*` helper binary
are all bundled here — nothing is read from `/usr/share/omarchy` at runtime.

Captured from: Omarchy 4.0.0-1 · Hyprland 0.56.2 · Lua 5.5.1 · theme `solitude`

## Layout

```
hypr-omarchy/
├── omarchy/          # portable $OMARCHY_PATH tree (bin/, config/, default/, themes/, shell/, ...)
├── hypr/             # your Hyprland config  ->  ~/.config/hypr/
├── omarchy-config/   # your shell/bar config ->  ~/.config/omarchy/
├── omarchy-state/    # current theme + toggles ->  ~/.local/state/omarchy/
├── install.sh        # one-shot replication installer
└── README.md
```

How the pieces fit together (the config chain that makes this work):

- `~/.config/hypr/hyprland.lua` is the single Hyprland entry point. It bootstraps
  Lua's `package.path` in three layers (see `omarchy/default/hypr/bootstrap.lua`):
  1. `~/.local/state/`   -> theme modules (`omarchy.current.theme.*`)
  2. `~/.config/`        -> your overrides (`hypr.monitors`, `hypr.input`, ...)
  3. `$OMARCHY_PATH/`    -> Omarchy defaults (`default.hypr.*`)
- `default.hypr.omarchy` loads helpers, bindings, envs, look-n-feel, input,
  windows, app rules and the current theme's `hyprland.lua` / `gum_env.lua`.
- `default.hypr.toggles` reads per-user toggles from `~/.local/state/omarchy/toggles/`.
- `envs.lua` sets `OMARCHY_PATH` in the session and prepends `$OMARCHY_PATH/bin`
  to `PATH`, so all `omarchy-*` keybindings resolve inside the bundle.

## Requirements on the target machine

- **Hyprland with Lua config support** (Hyprland 0.56+, built with `-DConfig_LUA=true`).
  The entry point is `hyprland.lua`, not `hyprland.conf`.
- **uwsm** (provides `uwsm`, `uwsm-app` — used by `o.launch()`).
- **Quickshell** (required for the bar/shell/lock; the shell sources live in
  `omarchy/shell/`).
- **systemd user session** + `dbus-update-activation-environment` (used by the
  default `autostart.lua`).
- Common helpers: `notify-send`, `findutils`, `bash`, `lua` (hyprland's Lua).
- Optional, used by keybindings if installed: `pamixer`/`wpctl`, `brightnessctl`,
  `grim`/`slurp`/`wl-copy` (screenshots), `udiskie`, `playerctl`, a browser.

## Setup

### Automatic (recommended)

The bundle ships `install.sh`, which deploys all three configs, wires up
`OMARCHY_PATH`, and appends the PATH export to `~/.profile`:

```bash
# Copy the bundle anywhere you like; this example keeps it in ~/.config
git clone ... ~/.config/hypr-omarchy        # or rsync/scp the folder as-is

cd ~/.config/hypr-omarchy
./install.sh --dry-run                       # preview what it will do
./install.sh                                 # deploy (backs up existing configs)
```

`install.sh` options:

```bash
./install.sh --force        # overwrite in place, skip the .bak.<timestamp> backups
./install.sh --no-profile   # don't touch ~/.profile (set OMARCHY_PATH yourself)
./install.sh --dry-run      # print actions without changing anything
```

### Manual

```bash
# 1. Copy the bundle anywhere you like; this example keeps it in ~/.config
git clone ... ~/.config/hypr-omarchy        # or rsync/scp the folder as-is

# 2. Point Omarchy at the bundle
export OMARCHY_PATH="$HOME/.config/hypr-omarchy/omarchy"
#    Persist it: add to ~/.profile (or /etc/profile.d/omarchy-path.sh).

# 3. Deploy the configs
cp -a "$HOME/.config/hypr-omarchy/hypr/."            ~/.config/hypr/       # your Hyprland config
cp -a "$HOME/.config/hypr-omarchy/omarchy-config/."  ~/.config/omarchy/    # shell/bar config
mkdir -p ~/.local/state
cp -a "$HOME/.config/hypr-omarchy/omarchy-state/."   ~/.local/state/omarchy/  # theme + toggles

# 4. Put the bundled binaries on PATH (Hyprland does this per-session too,
#    but you want it in your profile for pre-login tooling)
export PATH="$OMARCHY_PATH/bin:$PATH"

# 5. Log in to Hyprland. Sanity check:
hyprctl version && hyprctl configerrors
omarchy version
omarchy theme list
```

## What's replicated

- Window manager: keybindings, monitors, input, look-n-feel, window rules/app
  rules, animations, workspace layout toggles, autostart, nightlight
  (`hyprsunset.conf`), screen-sharing portal (`xdph.conf`).
- The current theme (`solitude`) including Hyprland border/rounding colors,
  GUM env vars, background, terminal/fastfetch/editor colors.
- The bar/shell layout (`shell.json`), extensions/menu, branding, hooks.
- All 428 helper binaries (`omarchy`, `omarchy-*`, `hyprland-preview-share-picker`)
  as real copies, not the package's `/usr/bin` symlinks.

## Known limitations (why "almost" one-to-one)

- **Shell plugins**: `~/.config/omarchy/plugins/` is included but empty here;
  clone any plugins with `omarchy plugin clone ...` on the target.
- **Distro/system services** the helpers expect: systemd user services, Power
  Profiles Daemon (`power-profiles-daemon`), a notification daemon (Quickshell),
  and the font icon set used by the bar are not shipped by this bundle.
- `omarchy-system-factory-reset` / `omarchy-upgrade-*` are Arch/Omarchy-specific
  and won't apply on other distros.
- `hyprland-preview-share-picker` is a compiled binary bundled here, but your
  distro must provide matching XDPH/wlroots shared libraries.

## Refresh / reset on the target

The `omarchy` CLI in the bundle works for user-level commands:

```bash
$OMARCHY_PATH/bin/omarchy commands          # list everything
$OMARCHY_PATH/bin/omarchy refresh shell     # reset bar to defaults (backs up first)
$OMARCHY_PATH/bin/omarchy refresh hyprland  # reset Hyprland Lua configs
```

## Source of truth

This bundle is a snapshot. To capture a fresh one from a live Omarchy system:

```bash
mkdir -p ~/.config/hypr-omarchy
rsync -a --exclude bin/ /usr/share/omarchy/ ~/.config/hypr-omarchy/omarchy/
cp -aL /usr/bin/omarchy /usr/bin/omarchy-* /usr/bin/hyprland-preview-share-picker \
       ~/.config/hypr-omarchy/omarchy/bin/
rsync -a ~/.config/hypr/    ~/.config/hypr-omarchy/hypr/
rsync -a ~/.config/omarchy/ ~/.config/hypr-omarchy/omarchy-config/
mkdir -p ~/.config/hypr-omarchy/omarchy-state
rsync -aL ~/.local/state/omarchy/current ~/.local/state/omarchy/toggles \
       ~/.config/hypr-omarchy/omarchy-state/
```
