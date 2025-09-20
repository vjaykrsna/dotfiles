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

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "../core/installer.sh" # For logging and utility functions
fi

# --- CONFIGURATION ---
EXTENSIONS_FILE="$HOME/.config/gnome-shell/extensions.txt"

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

    # Compile schemas for newly installed extensions
    info "Compiling GNOME extension schemas..."
    for ext_uuid in $(cat "$EXTENSIONS_FILE"); do
        ext_path="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"
        if [ -d "$ext_path/schemas" ]; then
            info "Compiling schemas for $ext_uuid..."
            glib-compile-schemas "$ext_path/schemas"
        fi
    done
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
        echo "Invalid option. Exiting."
        exit 1
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
    echo "Usage: $0 {save|install|interactive}"
    echo "If no argument provided, runs in interactive mode."
    exit 1
    ;;
esac
