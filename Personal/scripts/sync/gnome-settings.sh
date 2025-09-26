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

source "$SCRIPT_DIR/../utils/bootstrap.sh"

# The file where settings will be stored, tracked by yadm
SETTINGS_FILE="$HOME/.config/dconf/gnome_settings.ini"

# Ensure the directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

# --- SAVE FUNCTION ---
save_settings() {
    save_resource "GNOME settings" "$SETTINGS_FILE" 'dconf dump /org/gnome/'
}

# --- LOAD FUNCTION ---
load_settings() {
    load_resource "GNOME settings" "$SETTINGS_FILE" 'dconf load /org/gnome/'
    echo "   You may need to log out and back in for all changes to apply."
}

# --- DIFF FUNCTION ---
diff_settings() {
    diff_resource "GNOME settings" "$SETTINGS_FILE" 'dconf dump /org/gnome/'
}

# --- INTERACTIVE MODE ---
interactive_mode() {
    info "GNOME Settings Management:"
    select choice in "Save (dump) current GNOME settings" "Load (restore) GNOME settings" "Diff current vs saved"; do
        case $REPLY in
        1)
            save_settings
            break
            ;;
        2)
            load_settings
            break
            ;;
        3)
            diff_settings
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
        esac
    done
}

# --- MAIN LOGIC ---
case "$1" in
save)
    save_settings
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
