# pkgmap — package name translation

Part of the cross-distro rework (see `PLAN.md`). Once the `omarchy-pm` backend layer lands, the menu's Install/Remove flows translate Arch package names to your distro through this file.

## What it does

Omarchy's menu and installers reference **Arch package names** (`cursor-bin`, `bitwarden`, `ttf-cascadia-mono-nerd`, …). On non-Arch distros those names don't exist. `pkgmap.conf` maps each Arch name to the equivalent package on your distro — or to a Flatpak app, or marks it unsupported.

## Location

User-editable, in your state config:

```
omarchy-config/pkgmap/pkgmap.conf
```

It lives in *state* (not the runtime repo) so it survives `omarchy update` and is shared across your machines via your state repo.

## Format

One mapping per line. `#` starts a comment. A line may declare several backends at once:

```
<arch-name> | dnf=<pkg> | apt=<pkg> | flatpak=<app-id> | pacman=<pkg> | unsupported
```

Rules:

- **`<arch-name>`** is the Arch/AUR name the menu uses — always present.
- At least one target must be given; `unsupported` alone means "knowingly not available on this distro" (menu shows a graceful notice instead of a pacman error).
- `flatpak=<app-id>` is used as the **fallback** when the distro backend has no entry — so you only need `flatpak=` when the package isn't in the distro repo.
- Unknown Arch names (no line) behave like a missing entry: try distro repo, then Flatpak fallback, then "not available".

## How `omarchy-pm` resolves an install

1. Look up `<arch-name>` in `pkgmap.conf`.
2. If a target exists for the active backend (`dnf`, `apt`, `pacman`) → install it.
3. Else if a `flatpak=` target exists → install via Flatpak.
4. Else → "not available on this distro" notice.

## Worked examples

Real Arch names currently used by the menu and installers, with Fedora/Flatpak targets to get you started. Verify names with `dnf search` / `flatpak search` — they change.

| Arch name (menu) | dnf (Fedora) | flatpak fallback |
|---|---|---|
| `cursor-bin` | `cursor` | — |
| `visual-studio-code-bin` | `code` | `com.visualstudio.code` |
| `bitwarden` `bitwarden-cli` | `bitwarden` | `com.bitwarden.desktop` |
| `sublime-text-4` | — | `com.sublimetext.4` |
| `minecraft-launcher` | — | `com.mojang.Minecraft` |
| `lmstudio-bin` | — | `ai.lmstudio.LMStudio` |
| `ollama` / `ollama-cuda` / `ollama-rocm` | `ollama` | — |
| `grok-bot` | — | — (unsupported) |
| `heroic-games-launcher-bin` | — | `com.heroicgameslauncher.hgl` |
| `nordvpn-bin` | — | — (unsupported) |
| `once-bin` | — | — (unsupported) |
| `spotify` | `spotify` | `com.spotify.Client` |
| `signal-desktop` | `signal-desktop` | `org.signal.Signal` |
| `dropbox` | `dropbox` | `com.dropbox.Client` |
| `tailscale` | `tailscale` | — |
| `sunshine` | `sunshine` | `dev.lizardbyte.app.Sunshine` |
| `steam` | `steam` | `com.valvesoftware.Steam` |
| `retroarch` + `libretro-*` cores | `retroarch` + cores | `org.libretro.RetroArch` |
| `lutris` `umu-launcher` `wine-staging` | `lutris` `wine` | `net.lutris.Lutris` |
| `ttf-cascadia-mono-nerd` | `cascadia-code-fonts` | — |
| `ttf-firacode-nerd` | `fira-code-fonts` | — |
| `ttf-meslo-nerd` | — | — (unsupported, or Nerd Fonts download) |
| `ttf-iosevka-nerd` | `iosevka-fonts` | — |
| `xpadneo-dkms` | — | — (unsupported: vendor driver only) |
| `supergfxctl` | — | — (unsupported: ASUS hardware only) |

### Example file (Fedora)

```ini
# omarchy-config/pkgmap/pkgmap.conf — Fedora example
cursor-bin            | dnf=cursor
visual-studio-code-bin| dnf=code
bitwarden             | dnf=bitwarden
bitwarden-cli         | dnf=bitwarden-cli
sublime-text-4        | flatpak=com.sublimetext.4
minecraft-launcher    | flatpak=com.mojang.Minecraft
lmstudio-bin          | flatpak=ai.lmstudio.LMStudio
ollama                | dnf=ollama
steam                 | dnf=steam
retroarch             | dnf=retroarch
spotify               | dnf=spotify
signal-desktop        | dnf=signal-desktop
ttf-cascadia-mono-nerd| dnf=cascadia-code-fonts
grok-bot              | unsupported
```

## Finding the right package name

- **dnf**: `dnf search <keyword>` (e.g. `dnf search cursor`), or check https://packages.fedoraproject.org
- **apt**: `apt search <keyword>`, or https://packages.ubuntu.com
- **flatpak**: `flatpak search <keyword>` — prefer the distro repo first, Flatpak only as fallback
- **unsupported**: some Arch-only packages have no equivalent (DKMS drivers for specific hardware, binaries distributed only via AUR) — mark them `unsupported` so the menu fails gracefully instead of erroring.

## Troubleshooting

- Install fails with "Package X did not install" → the dnf/apt name is wrong; run the same `dnf install X` manually to see the real name.
- Flatpak install never triggers → a `dnf=`/`apt=` entry exists but the package name is bad; fix the name or delete the entry to fall through to Flatpak.
- Menu still shows the old behavior → the backend layer isn't active yet (implementation phase, see `PLAN.md`).