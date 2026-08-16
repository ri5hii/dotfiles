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
├── update-dot.sh     # refresh the bundle from a live Omarchy device
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
./install.sh --force         # overwrite in place, skip the .bak.<timestamp> backups
./install.sh --no-profile    # don't touch ~/.profile (set OMARCHY_PATH yourself)
./install.sh --app-configs   # also deploy Omarchy's app config templates to ~/.config/
./install.sh --systemd       # install Omarchy systemd user units (path-rewritten) + enable
./install.sh --check-deps    # check dependencies and exit (nonzero if required deps missing); deploys nothing
./install.sh --dry-run       # print actions without changing anything
```

`--check-deps` verifies required commands (Hyprland 0.56+ with Lua config
support, `uwsm`, `uwsm-app`, `quickshell`, `notify-send`, `bash`), reports
optional keybinding helpers, and exits 0/1 without touching the system — run it
first on the target to see what to install.

`--app-configs` deploys the bundled templates for terminals, starship, git, tmux,
btop, lazygit, fcitx5, wireplumber, etc. (everything under `omarchy/config/`
except `hypr/` and `omarchy/`, which are always deployed from your customized
versions). `--systemd` installs the shipped user units (crash-watch, sleep-lock,
speaker-tuning, ...) with their `ExecStart` paths rewritten from `/usr/bin/`
to this bundle, so they run without a system-wide Omarchy install.

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

## After installing — things you do yourself

`install.sh` deploys the configs and wires up the environment, but a few things
are inherently manual — they need a package manager, your identity, or root:

- **System packages the bundle can't ship**: Hyprland built with Lua config
  support (0.56+, `-DConfig_LUA=true` — this may mean building it yourself or a
  distro build with that flag), `uwsm`, `quickshell`, and
  `power-profiles-daemon` (enable its service). Common helpers: `notify-send`
  (libnotify), `findutils`, `bash`, `lua`.
- **A Nerd Font** (e.g. JetBrainsMono Nerd Font): the bar/OSD style expects one
  and falls back to `monospace` without it.
- **Optional per-keybinding helpers**, if you use those keybindings:
  `pamixer`/`wpctl`, `brightnessctl`, `grim`/`slurp`/`wl-copy` (screenshots),
  `udiskie`, `playerctl`, a browser.
- **Git identity** (Omarchy's provisioning normally sets this for you):
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@host"
  ```
- **Shell plugins**: `~/.config/omarchy/plugins/` is deployed empty — clone the
  ones you want:
  ```bash
  $OMARCHY_PATH/bin/omarchy plugin list      # what's available
  $OMARCHY_PATH/bin/omarchy plugin clone <name> ...
  ```
- **Optional user bits** (see `omarchy/install/user/`): default keyring
  (`default-keyring.sh`), `mise` runtime manager (`mise.sh`), chromium defaults
  (`chromium.sh`).
- **OS-level integration (root)**: enable `power-profiles-daemon.service`; the
  optional systemd user units via `install.sh --systemd`; boot/login theming
  (`omarchy/default/{sddm,limine,plymouth}`) if you want it beyond the desktop.
- **First boot**: log out and back in so `~/.profile` PATH exports apply, start
  the session from the installed `omarchy.desktop` (uwsm), then sanity check:
  ```bash
  hyprctl configerrors && omarchy version && omarchy theme list
  ```

## Updating the bundle from a device

`update-dot.sh` does the reverse of `install.sh`: run it on any machine and it
re-captures that machine's Omarchy state back into the bundle. It is
device-aware — each source is refreshed only if present, and missing sources are
reported and skipped (e.g. on a non-Omarchy box the `omarchy/` tree and `bin/`
are skipped, but your `hypr/` and `omarchy-config/` are still captured).

```bash
cd ~/.config/hypr-omarchy
./update-dot.sh --dry-run          # preview: live log, nothing written
./update-dot.sh                    # apply the refresh
./update-dot.sh --prune            # mirror sources: drop files no longer on the device
```

`update-dot.sh` options:

```bash
./update-dot.sh --dry-run   # show what would change without writing anything
./update-dot.sh --prune     # --delete mirroring (removes stale bundle files)
./update-dot.sh --no-log    # don't write update-dot.log
./update-dot.sh --help
```

Each run streams a concise, colorized live log to the terminal (color is skipped
when stdout is not a TTY) and writes `update-dot.log` (in the bundle dir,
gitignored), then prints a final report of what changed per source with timings.
There is no auto-commit; when the bundle lives in a git worktree the script
prints the changed-file status for you to review and commit.

What it captures (when present on the device):

| Source on device                                   | Bundle target        |
|----------------------------------------------------|----------------------|
| `/usr/share/omarchy/` (live Omarchy install)       | `omarchy/` (minus `bin/`) |
| `/usr/bin/omarchy*` + `hyprland-preview-share-picker` | `omarchy/bin/` (real copies) |
| `~/.config/hypr/`                                  | `hypr/`              |
| `~/.config/omarchy/`                               | `omarchy-config/`    |
| `~/.local/state/omarchy/{current,toggles}`         | `omarchy-state/`     |

Runtime junk (clipboard history, notifications, agents, logs) is never captured.

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
- **Distro/system services** the helpers expect: Power Profiles Daemon
  (`power-profiles-daemon`), a notification daemon (Quickshell), and the font
  icon set used by the bar are not shipped by this bundle. Systemd user services
  are bundled and can be installed with `install.sh --systemd` (path-rewritten
  to the bundle), but any that need fcitx5/tailscale/Bluetooth also require
  those programs installed.
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

This bundle is a snapshot. `update-dot.sh` automates the recapture below — these
commands are what it runs under the hood. To capture a fresh one from a live
Omarchy system:

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
