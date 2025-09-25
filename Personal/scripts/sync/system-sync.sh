#!/usr/bin/env bash
# system-sync.sh - Save or diff system-level configurations
# Usage: ./system-sync.sh {save|diff|interactive}
# Example: ./system-sync.sh save
set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION ---
CONFIG_DIR="$HOME/.config/system-config"
mkdir -p "$CONFIG_DIR"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utility functions
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them
trap 'error "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# --- SAVE FUNCTION ---
save_configs() {
    info "Saving system configurations..."

    # Save crontab
    crontab -l > "$CONFIG_DIR/crontab.txt" || error "Failed to save crontab"

    # Save fstab
    cp /etc/fstab "$CONFIG_DIR/fstab" || error "Failed to copy fstab"

    # Save hosts file
    cp /etc/hosts "$CONFIG_DIR/hosts" || error "Failed to copy hosts"

    ok "System configurations saved to $CONFIG_DIR."
}

# --- DIFF FUNCTION ---
diff_configs() {
    info "Comparing stored configurations with live system..."

    info "--- Crontab ---"
    diff -u "$CONFIG_DIR/crontab.txt" <(crontab -l) || true

    info "--- fstab ---"
    diff -u "$CONFIG_DIR/fstab" /etc/fstab || true

    info "--- hosts ---"
    diff -u "$CONFIG_DIR/hosts" /etc/hosts || true
}

# --- INTERACTIVE MODE ---
interactive_mode() {
    echo "System Configuration Management:"
    echo "1. Save (backup) current system configs"
    echo "2. Compare (diff) configs with saved version"
    echo -n "Choose an option (1-2): "
    read -r choice

    case "$choice" in
    1)
        save_configs
        ;;
    2)
        diff_configs
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
    save_configs
    ;;
diff)
    diff_configs
    ;;
interactive | "")
    interactive_mode
    ;;
*)
    echo "Usage: $0 {save|diff|interactive}"
    echo "If no argument provided, runs in interactive mode."
    exit 1
    ;;
esac
