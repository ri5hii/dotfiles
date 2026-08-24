# Menu override — making the SUPER+SPACE menu yours

Part of the cross-distro rework (see `PLAN.md`). Once the rework lands, the menu you see is the menu you own.

## How it works

The menu definition (`omarchy-menu.jsonc`) lives in the **runtime** repo and is replaced wholesale on `omarchy update`. If you edited it there, your changes would be overwritten (or conflict). So your personal copy lives in **state**:

```
omarchy-config/omarchy-menu.jsonc
```

At load time the menu uses:

1. `omarchy-config/omarchy-menu.jsonc` **if it exists — it fully replaces the runtime copy** (nothing is merged).
2. Otherwise, the runtime default.

One file, one rule, zero merge conflicts. Your copy is committed in your state repo and follows you across machines.

> Two extras on top of the replacement model:
> - **Extensions still merge**: Omarchy's own extension file (`~/.config/omarchy/extensions/omarchy-menu.jsonc`) is merged over whatever base is active (replacement or default) — per-id overrides, plus new entries. Handy for additions that shouldn't live in your big override file.
> - **`when:` guards**: any entry may carry `"when": "<shell command>"` — the row is hidden when the command exits nonzero. The shipped default uses this so `Install → AUR` only shows when `yay` is installed.

## Getting started

```bash
# bootstrap your personal copy from the current runtime default
mkdir -p ~/.config/omarchy
cp "$OMARCHY_PATH/default/omarchy/omarchy-menu.jsonc" ~/.config/omarchy/omarchy-menu.jsonc

# edit it
omarchy-launch-config-editor ~/.config/omarchy/omarchy-menu.jsonc
```

Restart the menu (`Super+Space` → it reloads on open) and your version is live.

## What you'd typically change

- **Rename "Update" → "System Update"** and reorder the section to match the rework.
- **The AUR entry is already gated**: `Install → AUR` hides itself when `yay` isn't installed (a `when:` guard in the shipped menu). No config needed.
- **Add your own entries** — the file is plain JSONC: `{"label": "My App", "action": "my-app-command"}`.

## Keeping up with upstream — `omarchy-menu-diff`

Since your copy replaces the runtime one, new upstream entries won't appear automatically. Diff to see what you're missing:

```bash
omarchy-menu-diff
```

Shows a side-by-side diff of your `omarchy-config/omarchy-menu.jsonc` vs the runtime default. Port over what you want, keep the rest.

## Reference

| Aspect | Behavior |
|---|---|
| Override location | `omarchy-config/omarchy-menu.jsonc` |
| Merge semantics | **None** — full replacement |
| Extensions file | `~/.config/omarchy/extensions/omarchy-menu.jsonc` merges on top (per-id) |
| Reset to default | delete the state file |
| Upstream changes | visible via `omarchy-menu-diff`; port manually |
| Menu file format | JSONC (JSON with `//` comments allowed) |
| AUR entry | `when: "command -v yay"` — hidden when yay is absent |

## Troubleshooting

- **Menu looks like the old default** → state file missing; check `~/.config/omarchy/omarchy-menu.jsonc` exists.
- **Menu won't load after an edit** → JSON syntax error; validate with `python3 -m json.tool` after stripping comments, or restore the bootstrap copy.
- **Want upstream's version back** → delete the state file and open the menu (runtime default takes over).