#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/vireline/laplace-nexus-cli"
INSTALL_DIR="$HOME/.laplace"
BIN_DIR="$HOME/.local/bin"
BIN_TARGET="$BIN_DIR/laplace"

echo "[Laplace] Starting installation..."

# create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "[Laplace] Updating existing installation..."
    git -C "$INSTALL_DIR" pull
else
    echo "[Laplace] Cloning Laplace repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ensure executable
chmod +x "$INSTALL_DIR/laplace.sh"

# symlink
ln -sf "$INSTALL_DIR/laplace.sh" "$BIN_TARGET"

# ensure PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "[Laplace] Added ~/.local/bin to PATH (restart shell)"
fi

echo
echo "[Laplace] Installation complete."
echo "Run with: laplace"

