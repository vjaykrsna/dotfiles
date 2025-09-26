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

source "$SCRIPT_DIR/../utils/bootstrap.sh"

# --- SAVE FUNCTION ---
save_configs() {
    info "Saving system configurations..."

    # Save crontab
    save_resource "crontab" "$CONFIG_DIR/crontab.txt" 'crontab -l'

    # Save fstab
    mkdir -p "$CONFIG_DIR"
    run_privileged cp /etc/fstab "$CONFIG_DIR/fstab" || error "Failed to copy fstab"

    # Save hosts file
    run_privileged cp /etc/hosts "$CONFIG_DIR/hosts" || error "Failed to copy hosts"

    ok "System configurations saved to $CONFIG_DIR."
}

# --- LOAD FUNCTION ---
load_configs() {
    warn "Loading system configs - this can be dangerous; ensure backups!"
    if [[ ! -f "$CONFIG_DIR/crontab.txt" ]]; then
        fatal "Crontab backup not found"
    fi
    crontab "$CONFIG_DIR/crontab.txt" || fatal "Failed to load crontab"
    ok "Crontab loaded."

    if [[ ! -f "$CONFIG_DIR/fstab" ]]; then
        fatal "fstab backup not found"
    fi
    run_privileged cp /etc/fstab /etc/fstab.bak || true
    run_privileged cp "$CONFIG_DIR/fstab" /etc/fstab || fatal "Failed to load fstab"
    ok "fstab loaded (original backed up)."

    if [[ ! -f "$CONFIG_DIR/hosts" ]]; then
        fatal "hosts backup not found"
    fi
    run_privileged cp /etc/hosts /etc/hosts.bak || true
    run_privileged cp "$CONFIG_DIR/hosts" /etc/hosts || fatal "Failed to load hosts"
    ok "hosts loaded (original backed up)."
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
    select choice in "Save (backup) current system configs" "Load (restore) saved configs" "Compare (diff) configs with saved version"; do
        case $REPLY in
        1)
            save_configs
            break
            ;;
        2)
            load_configs
            break
            ;;
        3)
            diff_configs
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
    save_configs
    ;;
load)
    load_configs
    ;;
diff)
    diff_configs
    ;;
interactive | "")
    interactive_mode
    ;;
*)
    fatal "Usage: $0 {save|load|diff|interactive}. If no argument provided, runs in interactive mode."
    ;;
esac
