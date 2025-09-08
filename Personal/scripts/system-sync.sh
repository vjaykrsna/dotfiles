#!/bin/bash
# ==============================================================================
# System Configuration Sync Script
#
# This script manages the syncing of system-level configuration files like
# crontab, fstab, and the hosts file.
#
# Usage:
#   ./system-sync.sh save   # Saves the current system configurations
#   ./system-sync.sh diff   # Compares the stored configs with the live ones
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION ---
CONFIG_DIR="$HOME/.config/system-config"
mkdir -p "$CONFIG_DIR"

# --- UTILITY FUNCTIONS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }

# --- SAVE FUNCTION ---
save_configs() {
    info "Saving system configurations..."
    
    # Save crontab
    crontab -l > "$CONFIG_DIR/crontab.txt"
    
    # Save fstab
    cp /etc/fstab "$CONFIG_DIR/fstab"
    
    # Save hosts file
    cp /etc/hosts "$CONFIG_DIR/hosts"
    
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

# --- MAIN LOGIC ---
case "${1:-}" in
    save)
        save_configs
        ;;
    diff)
        diff_configs
        ;;
    *)
        echo "Usage: $0 {save|diff}"
        exit 1
        ;;
esac
