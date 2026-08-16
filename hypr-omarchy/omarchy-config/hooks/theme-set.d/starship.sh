#!/bin/bash
# Sync the omarchy-themed starship config after every theme change.
cp "$HOME/.local/state/omarchy/current/theme/starship.toml" "$HOME/.config/starship.toml"
