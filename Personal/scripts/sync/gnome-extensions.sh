#!/usr/bin/env bash
# gnome-extensions.sh - Save and reinstall GNOME Shell extensions
# Usage: ./gnome-extensions.sh {save|install|interactive}
# Example: ./gnome-extensions.sh save
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh" # For logging functions
source "$SCRIPT_DIR/../utils/utils.sh" # For utility functions

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# --- CONFIGURATION ---
EXTENSIONS_FILE="$HOME/.config/gnome-shell/extensions.txt"

# --- SAVE FUNCTION ---
save_extensions() {
    info "Saving list of installed GNOME extensions to $EXTENSIONS_FILE..."
    mkdir -p "$(dirname "$EXTENSIONS_FILE")"
    # Use the built-in tool to reliably get the list of *enabled* extensions.
    # gext does not have a simple flag for this.
    gnome-extensions list --enabled | cut -d' ' -f1 > "$EXTENSIONS_FILE" || fatal "Failed to save extension list"
    ok "Extension list saved."
}

# --- INSTALL FUNCTION ---
install_extensions() {
    if [ ! -s "$EXTENSIONS_FILE" ]; then
        info "No extension list found or list is empty. Skipping installation."
        return
    fi

    info "Installing GNOME extensions from $EXTENSIONS_FILE..."
    xargs -a "$EXTENSIONS_FILE" gext install || warn "Failed to install extensions (gext missing?)"

    ok "All extensions installed."

    # Compile schemas for newly installed extensions
    info "Compiling GNOME extension schemas..."
    while IFS= read -r ext_uuid; do
        ext_path="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"
        glib-compile-schemas "$ext_path/schemas" 2>/dev/null || true
    done < "$EXTENSIONS_FILE"
    ok "Schema compilation completed."
}

# --- INTERACTIVE MODE ---
interactive_mode() {
    echo "GNOME Extensions Management:"
    echo "1. Save list of installed extensions"
    echo "2. Install extensions from saved list"
    echo -n "Choose an option (1-2): "
    read -r choice

    case "$choice" in
    1)
        save_extensions
        ;;
    2)
        install_extensions
        ;;
    *)
        fatal "Invalid option."
        ;;
    esac
}

# --- MAIN LOGIC ---
case "${1:-}" in
save)
    save_extensions
    ;;
install)
    install_extensions
    ;;
interactive | "")
    interactive_mode
    ;;
    *)
    fatal "Usage: $0 {save|install|interactive}. If no argument provided, runs in interactive mode."
    ;;
esac
