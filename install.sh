#!/usr/bin/env bash
# install.sh — installs sbx-start from GitHub
# Usage: curl -fsSL https://raw.githubusercontent.com/your-org/sbx-toolkit/main/install.sh | bash
set -euo pipefail

REPO="maxkrivich/sbx-toolkit"
BRANCH="main"
BINARY="sbx-start"
RAW_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${BINARY}"

# ── resolve install dir ───────────────────────────────────────────────────────

if [[ -d "$HOME/bin" ]] && echo "$PATH" | grep -q "$HOME/bin"; then
	INSTALL_DIR="$HOME/bin"
elif [[ -d "$HOME/.local/bin" ]] && echo "$PATH" | grep -q "$HOME/.local/bin"; then
	INSTALL_DIR="$HOME/.local/bin"
else
	INSTALL_DIR="/usr/local/bin"
fi

INSTALL_PATH="$INSTALL_DIR/$BINARY"

# ── check dependencies ────────────────────────────────────────────────────────

command -v curl >/dev/null 2>&1 || {
	echo "ERROR: curl is required." >&2
	exit 1
}

# ── download ──────────────────────────────────────────────────────────────────

echo "→ Downloading $BINARY"
if ! curl -fsSL "$RAW_URL" -o "$INSTALL_PATH" 2>/dev/null; then
	echo "→ Retrying with sudo to /usr/local/bin..."
	INSTALL_DIR="/usr/local/bin"
	INSTALL_PATH="$INSTALL_DIR/$BINARY"
	sudo curl -fsSL "$RAW_URL" -o "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

# ── verify ────────────────────────────────────────────────────────────────────

echo "✓ Installed to $INSTALL_PATH"

if command -v "$BINARY" >/dev/null 2>&1; then
	echo "✓ $BINARY is on your PATH"
else
	echo ""
	echo "NOTE: Add $INSTALL_DIR to your PATH:"
	echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
	echo ""
fi

echo ""
echo "Next steps:"
echo "  1. Run: ./sbx-setup --config ~/.claude"
echo "  2. Run: sbx-start"
echo ""
echo "Full docs: https://github.com/${REPO}"
