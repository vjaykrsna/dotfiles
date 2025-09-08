#!/bin/bash
# ==============================================================================
# GNOME Shell Extension Management Script
#
# This script manages GNOME Shell extensions by saving a list of installed
# extensions and reinstalling them from the official GNOME Extensions website.
#
# Usage:
#   ./gnome-extensions.sh save   # Saves the list of installed extensions
#   ./gnome-extensions.sh install # Installs extensions from the list
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION ---
EXTENSIONS_FILE="$HOME/.config/gnome-shell/extensions.txt"

# --- UTILITY FUNCTIONS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }

# --- SAVE FUNCTION ---
save_extensions() {
    info "Saving list of installed GNOME extensions to $EXTENSIONS_FILE..."
    mkdir -p "$(dirname "$EXTENSIONS_FILE")"
    # Use the built-in tool to reliably get the list of *enabled* extensions.
    # gext does not have a simple flag for this.
    gnome-extensions list --enabled | cut -d' ' -f1 > "$EXTENSIONS_FILE"
    ok "Extension list saved."
}

# --- INSTALL FUNCTION ---
install_extensions() {
    if [ ! -s "$EXTENSIONS_FILE" ]; then # Check if file is non-empty
        info "No extension list found or list is empty. Skipping installation."
        return
    fi

    if ! command -v gext &> /dev/null; then
        echo "Error: 'gext' (from gnome-extensions-cli) is not installed."
        echo "Please ensure it is installed via pipx."
        exit 1
    fi

    info "Installing GNOME extensions from $EXTENSIONS_FILE..."
    # Pass all extensions from the file to a single install command.
    # xargs removes newlines and passes them as separate arguments.
    xargs -a "$EXTENSIONS_FILE" gext install
    ok "All extensions installed."
}

# --- MAIN LOGIC ---
case "${1:-}" in
    save)
        save_extensions
        ;;
    install)
        install_extensions
        ;;
    *)
        echo "Usage: $0 {save|install}"
        exit 1
        ;;
esac
