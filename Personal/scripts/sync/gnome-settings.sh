#!/usr/bin/env bash
# ==============================================================================
# GNOME/dconf Settings Sync Script for yadm
#
# This script manages GNOME settings by exporting them to a human-readable
# text file and loading them back. This is a robust way to sync settings
# across machines without tracking the binary dconf database.
#
# Usage:
#   ./gnome-settings.sh dump   # Exports current settings to the file
#   ./gnome-settings.sh load   # Loads settings from the file
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utility functions
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# The file where settings will be stored, tracked by yadm
SETTINGS_FILE="$HOME/.config/dconf/gnome_settings.ini"

# Ensure the directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

# --- DUMP FUNCTION ---
# Dumps all dconf settings to the text file
dump_settings() {
    info "Dumping GNOME settings to $SETTINGS_FILE..."
    dconf dump /org/gnome/ > "$SETTINGS_FILE" || fatal "Failed to dump settings"
    ok "Done. You can now commit the changes with yadm."
}

# --- LOAD FUNCTION ---
# Loads settings from the text file into dconf
load_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        fatal "Settings file not found at $SETTINGS_FILE. Please run './gnome-settings.sh dump' on your source machine first."
    fi
    info "Loading GNOME settings from $SETTINGS_FILE..."
    dconf load /org/gnome/ < "$SETTINGS_FILE" || fatal "Failed to load settings"
    ok "Done. Your GNOME settings have been restored."
    echo "   You may need to log out and back in for all changes to apply."
}

# Add DIFF FUNCTION
diff_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        fatal "Settings file not found at $SETTINGS_FILE. Please run './gnome-settings.sh dump' on your source machine first."
    fi
    info "Diffing current vs saved GNOME settings..."
    diff -u <(dconf dump /org/gnome/) "$SETTINGS_FILE" || true
}

# --- INTERACTIVE MODE ---
interactive_mode() {
    info "GNOME Settings Management:"
    echo "1. Save (dump) current GNOME settings"
    echo "2. Load (restore) GNOME settings"
    echo "3. Diff current vs saved"
    echo -n "Choose an option (1-3): "
    read -r choice

    case "$choice" in
    1)
        dump_settings
        ;;
    2)
        load_settings
        ;;
    3)
        diff_settings
        ;;
    *)
        fatal "Invalid option."
        ;;
    esac
}

# --- MAIN LOGIC ---
case "$1" in
dump)
    dump_settings
    ;;
load)
    load_settings
    ;;
diff)
    diff_settings
    ;;
interactive | "")
    interactive_mode
    ;;
*)
    fatal "Usage: $0 {dump|load|diff|interactive}. If no argument provided, runs in interactive mode."
    ;;
esac
