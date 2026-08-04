#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo cp "$DIR/llamacpp.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now llamacpp.service
