#!/usr/bin/env bash
set -e

echo "[Laplace] Installing Laplace..."

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET="/usr/local/bin/laplace"

# ensure script executable
chmod +x "$SCRIPT_DIR/laplace.sh"

# if not root, re-run with sudo
if [ "$EUID" -ne 0 ]; then
  echo "[Laplace] Needs sudo to install to $TARGET"
  sudo bash "$SCRIPT_DIR/install.sh"
  exit 0
fi

# create/overwrite symlink
ln -sf "$SCRIPT_DIR/laplace.sh" "$TARGET"

echo "[Laplace] Installed successfully."
echo "[Laplace] Run: laplace"
