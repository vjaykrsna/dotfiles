#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "$0")/installer.sh" # For logging and utility functions
fi

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
    # Multiple passes to handle dependency order
    for pass in {1..3}; do
        remaining_snaps=$(snap list | awk 'NR>1 {print $1}')
        if [[ -z "$remaining_snaps" ]]; then
            break
        fi
        info "Removal pass $pass..."
        for snap in $remaining_snaps; do
            info "Removing $snap..."
            run_privileged snap remove "$snap" || warn "Could not remove $snap, maybe required by another snap."
        done
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
