#!/usr/bin/env bash
# install.sh — installs sbx-start and sbx-setup from GitHub
# Usage: curl -fsSL https://raw.githubusercontent.com/your-org/sbx-toolkit/main/install.sh | bash
set -euo pipefail

REPO="maxkrivich/sbx-toolkit"
BRANCH="main"
BINARIES=("sbx-start" "sbx-setup")
TEMPLATE_FILES=(
	"templates/README.md"
	"templates/base/Dockerfile"
	"templates/mise/Dockerfile"
)
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/sbx-toolkit"

# ── resolve install dir ───────────────────────────────────────────────────────

if echo "$PATH" | grep -q "$HOME/bin"; then
	INSTALL_DIR="$HOME/bin"
elif echo "$PATH" | grep -q "$HOME/.local/bin"; then
	INSTALL_DIR="$HOME/.local/bin"
elif [[ -w "/usr/local/bin" ]]; then
	INSTALL_DIR="/usr/local/bin"
else
	INSTALL_DIR="$HOME/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

# ── check dependencies ────────────────────────────────────────────────────────

command -v curl >/dev/null 2>&1 || {
	echo "ERROR: curl is required." >&2
	exit 1
}

# ── install binaries ──────────────────────────────────────────────────────────

for binary in "${BINARIES[@]}"; do
	raw_url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${binary}"
	install_path="$INSTALL_DIR/$binary"

	echo "→ Downloading $binary"
	if ! curl -fsSL "$raw_url" -o "$install_path"; then
		echo "ERROR: Failed to install $binary to $install_path" >&2
		echo "       Choose a writable directory in PATH or rerun with elevated permissions." >&2
		exit 1
	fi

	chmod +x "$install_path"
	echo "✓ Installed to $install_path"
done

# ── install templates for sbx-setup ──────────────────────────────────────────

echo "→ Installing templates to $DATA_DIR/templates"
for template_file in "${TEMPLATE_FILES[@]}"; do
	target_path="$DATA_DIR/$template_file"
	target_dir="$(dirname "$target_path")"
	url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${template_file}"

	mkdir -p "$target_dir"
	if ! curl -fsSL "$url" -o "$target_path"; then
		echo "ERROR: Failed to download $template_file" >&2
		exit 1
	fi
done
echo "✓ Templates installed to $DATA_DIR/templates"

# ── verify ────────────────────────────────────────────────────────────────────

missing=()
for binary in "${BINARIES[@]}"; do
	if command -v "$binary" >/dev/null 2>&1; then
		echo "✓ $binary is on your PATH"
	else
		missing+=("$binary")
	fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
	echo ""
	echo "NOTE: Add $INSTALL_DIR to your PATH:"
	echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
	echo ""
fi

echo ""
echo "Next steps:"
echo "  1. Run: sbx-setup --config ~/.claude"
echo "  2. Run: sbx-start"
echo ""
echo "Templates location: $DATA_DIR/templates"
echo ""
echo "Full docs: https://github.com/${REPO}"
