#!/bin/bash
# zsh config installer & setup script
# Usage: bash scripts/run_zsh.sh

set -e

ZSH_CONFIG_DIR="$(dirname "$0")/../config/zsh"
ZSH_TARGET_DIR="$HOME/.config/zsh"

# 1. Run install_zsh.sh from config/zsh (if exists and executable)
if [ -x "$ZSH_CONFIG_DIR/install_zsh.sh" ]; then
    "$ZSH_CONFIG_DIR/install_zsh.sh"
elif [ -f "$ZSH_CONFIG_DIR/install_zsh.sh" ]; then
    bash "$ZSH_CONFIG_DIR/install_zsh.sh"
fi

# 2. Create target config directory if not exists
mkdir -p "$ZSH_TARGET_DIR"

# 3. Copy all config files (excluding README.md)
find "$ZSH_CONFIG_DIR" -type f ! -name "README.md" -exec cp {} "$ZSH_TARGET_DIR/" \;

# 4. Copy functions directory
if [ -d "$ZSH_CONFIG_DIR/functions" ]; then
    mkdir -p "$ZSH_TARGET_DIR/functions"
    cp -r "$ZSH_CONFIG_DIR/functions"/* "$ZSH_TARGET_DIR/functions/"
fi

# 5. Set up ~/.zshrc symlink
if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi
ln -sf "$ZSH_CONFIG_DIR/zshrc" "$HOME/.zshrc"

# 6. Print success message
cat <<EOF
Zsh config installed!
- install_zsh.sh executed
- Config files copied to: $ZSH_TARGET_DIR
- ~/.zshrc symlinked to: $ZSH_CONFIG_DIR/zshrc
- Previous ~/.zshrc backed up if existed

To apply changes, restart your terminal or run: source ~/.zshrc
EOF
