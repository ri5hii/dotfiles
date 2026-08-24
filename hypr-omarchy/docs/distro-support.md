# Distro support matrix

Part of the cross-distro rework (see `PLAN.md`). `install.sh` becomes the per-distro glue layer: it deploys the bundle the same way everywhere, but maps dependencies per distro and degrades Arch-only features to notices.

## How install.sh stays distro-agnostic

- Deps are checked by **command presence** (`command -v hyprland`), not by package manager — this already works today (`--check-deps`).
- The rework adds a **dep mapping table** per distro: for each command the bundle needs, install the right package (`dnf install hyprland` vs `pacman -S hyprland` vs a build-from-source note for quickshell).
- Arch-only install steps (PAM lock, snapper, limine, Plymouth) become **non-fatal notices**: installed when available, explained when not.
- Everything after deps (config deploy, profile glue, systemd user units) is already distro-neutral.

## Matrix

| Component | Arch (native) | Fedora 42+ | Debian 13 / Ubuntu 24.04+ | Notes |
|---|---|---|---|---|
| `hyprland` | pacman | dnf (`hyprland`) | apt / PPA | Hyprland is in Fedora and Debian repos; Ubuntu via [hyprland PPA](https://launchpad.net/~hyprland-ppa). |
| `quickshell` | pacman (`quickshell`) | **build from source** (guide below) | **build from source** | Only real hard dependency; no distro packages outside Arch. |
| `uwsm` | pacman | dnf (`uwsm`) | apt (`uwsm`) | Packaged in Fedora; on Debian via backports/PPA, else build from source. |
| display manager | `sddm` | `sddm` | `sddm` | Optional: Hyprland can be started from `uwsm` on a plain TTY; DM is a convenience. |
| `gum` | pacman | dnf (`gum`) | apt (`gum`) | Packaged in Fedora; Debian via PPA/upstream binary. |
| nerd fonts | pacman (`ttf-*-nerd`) | dnf (`*-nerd-fonts` subsets) | apt / manual | Fewer nerd-font packages on Fedora; see `pkgmap` for font entries. |
| `playerctl`, `brightnessctl`, `udiskie`, `wtype`, `grim`, `slurp`, `hyprpicker` | pacman | dnf | apt | All in Fedora/Debian repos; names in the dep mapping table. |
| PAM lock (fingerprint/fido2/faillock) | install script | non-fatal notice | non-fatal notice | `pam-u2f`, `fprintd` exist on Fedora; behavior differs per distro. |
| snapper (snapshots) | pacman | dnf (`snapper`) | notice | Fedora uses `snapper` + btrfs; works but config differs. |
| limine / direct boot | pacman + mkinitcpio | **notice only** | **notice only** | Arch-specific bootloader flow; other distros keep their own bootloader. |
| Plymouth | pacman | dnf (`plymouth`) | notice | Branding works, but initrd rebuild commands differ per distro. |

## Quickshell build guide (Fedora / Debian)

Quickshell is the shell framework Omarchy's bar runs on. Not packaged outside Arch — build it once:

```bash
# Fedora
sudo dnf install git cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel \
  qt6-qtsvg-devel qt6-qtwebsockets-devel qt6-qtshadertools-devel \
  qt6-qt5compat-devel qt6-qtwayland-devel wayland-devel wayland-protocols-devel

# Debian/Ubuntu
sudo apt install git cmake ninja-build qt6-base-dev qt6-declarative-dev \
  qt6-svg-dev qt6-websockets-dev qt6-shadertools-dev qt6-5compat-dev \
  qt6-wayland-dev libwayland-dev wayland-protocols

git clone --depth 1 https://github.com/outfoxxed/quickshell /tmp/quickshell
cd /tmp/quickshell
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build -j"$(nproc)"
sudo cmake --install build
```

Verify: `quickshell --version`. The bar then launches through `quickshell` like on Arch — nothing else differs.

## install.sh behaviors per phase

| Behavior | Today | After rework |
|---|---|---|
| Dep checks | `command -v`, report only | report + optional per-distro install commands |
| `--check-deps` exit code | nonzero if required missing | same, plus per-distro hint text |
| Arch-only installs (PAM/snapper/limine/Plymouth) | attempted | attempted on Arch, notices elsewhere |
| systemd user units | path-rewritten to bundle | same (already distro-neutral) |
| `--app-configs`, `--no-profile`, `--force`, `--dry-run` | yes | unchanged |

## Distro bring-up checklist (new install.sh target)

1. Fill in the dep mapping table for the distro's package manager.
2. Run `install.sh --check-deps`; iterate until required deps are green (build quickshell if needed).
3. Run a full install with `--systemd`; verify bar, menu, and one install flow from the menu.
4. Ship a `pkgmap.conf` preset and `system-update.conf` preset for the distro (see those guides).