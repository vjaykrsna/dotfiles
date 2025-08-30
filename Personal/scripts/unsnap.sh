#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies ---
source ./scripts/installer.sh # For logging and utility functions

run_snap_removal_interactive() {
    warn "🚨 Make sure you have backups! This will remove snap and its packages."
    read -rp "Continue? [y/N]: " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        error "Aborted."
        return
    fi

    info "Installed snaps:"
    snap list

    info "Removing all snap packages..."
    for snap in $(snap list | awk 'NR>1 {print $1}'); do
        info "Removing $snap..."
        run_privileged snap remove "$snap" || warn "Could not remove $snap, maybe required by another snap."
    done

    info "Stopping and disabling snap services..."
    run_privileged systemctl stop snapd
    run_privileged systemctl disable snapd

    info "Purging snapd package..."
    run_privileged apt purge snapd -y

    info "Cleaning leftover snap directories..."
    rm -rf ~/snap
    run_privileged rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd

    ok "Snap and all its packages removed."
}

# Allow running standalone or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_snap_removal_interactive
fi
