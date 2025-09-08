#!/bin/bash
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

# The file where settings will be stored, tracked by yadm
SETTINGS_FILE="$HOME/.config/dconf/gnome_settings.ini"

# Ensure the directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

# --- DUMP FUNCTION ---
# Dumps all dconf settings to the text file
dump_settings() {
  echo "Dumping GNOME settings to $SETTINGS_FILE..."
  dconf dump / > "$SETTINGS_FILE"
  echo "✅ Done. You can now commit the changes with yadm."
}

# --- LOAD FUNCTION ---
# Loads settings from the text file into dconf
load_settings() {
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo "❌ Error: Settings file not found at $SETTINGS_FILE."
    echo "Please run './gnome-settings.sh dump' on your source machine first."
    exit 1
  fi
  echo "Loading GNOME settings from $SETTINGS_FILE..."
  dconf load / < "$SETTINGS_FILE"
  echo "✅ Done. Your GNOME settings have been restored."
  echo "   You may need to log out and back in for all changes to apply."
}

# --- MAIN LOGIC ---
case "$1" in
  dump)
    dump_settings
    ;;
  load)
    load_settings
    ;;
  *)
    echo "Usage: $0 {dump|load}"
    exit 1
    ;;
esac
