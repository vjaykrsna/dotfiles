#!/usr/bin/env bash
# gnome-extensions.sh - Save and reinstall GNOME Shell extensions
# Usage: ./gnome-extensions.sh {save|install|interactive}
# Example: ./gnome-extensions.sh save
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/bootstrap.sh"

# --- CONFIGURATION ---
EXTENSIONS_FILE="$HOME/.config/gnome-shell/extensions.txt"

# --- SAVE FUNCTION ---
save_extensions() {
    save_resource "GNOME extensions" "$EXTENSIONS_FILE" 'gnome-extensions list --enabled | cut -d" " -f1'
}

# --- INSTALL FUNCTION ---
install_extensions() {
    if [ ! -s "$EXTENSIONS_FILE" ]; then
        info "No extension list found or list is empty. Skipping installation."
        return
    fi

    load_resource "GNOME extensions" "$EXTENSIONS_FILE" "xargs -a \"$EXTENSIONS_FILE\" gext install || warn \"Failed to install extensions (gext missing?)\""
    ok "All extensions installed."

    # Compile schemas for newly installed extensions
    info "Compiling GNOME extension schemas..."
    while IFS= read -r ext_uuid; do
        ext_path="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"
        glib-compile-schemas "$ext_path/schemas" 2>/dev/null || true
    done < "$EXTENSIONS_FILE"
    ok "Schema compilation completed."
}

# --- DIFF FUNCTION ---
diff_extensions() {
    diff_resource "GNOME extensions" "$EXTENSIONS_FILE" 'gnome-extensions list --enabled | cut -d" " -f1'
}

# --- INTERACTIVE MODE ---
interactive_mode() {
    echo "GNOME Extensions Management:"
    select choice in "Save list of installed extensions" "Install extensions from saved list" "Diff current vs saved"; do
        case $REPLY in
        1)
            save_extensions
            break
            ;;
        2)
            install_extensions
            break
            ;;
        3)
            diff_extensions
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
        esac
    done
}

# --- MAIN LOGIC ---
case "${1:-}" in
save)
    save_extensions
    ;;
load|install)
    install_extensions
    ;;
diff)
    diff_extensions
    ;;
interactive | "")
    interactive_mode
    ;;
*)
    fatal "Usage: $0 {save|load|diff|interactive}. If no argument provided, runs in interactive mode."
    ;;
esac
