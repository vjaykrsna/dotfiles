#!/usr/bin/env bash
# snap-removal.sh - Remove snapd and installed snaps
# Usage: ./snap-removal.sh
# Example: sudo ./snap-removal.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

run_snap_removal_interactive() {
    warn "🚨 Make sure you have backups! This will remove snap and its packages."

    if command -v snap >/dev/null 2>&1; then
        info "Installed snaps:"
        snap list

        info "Removing all snap packages..."
        # Multiple passes to handle dependency order
        for pass in {1..3}; do
            mapfile -t remaining_snaps < <(snap list | awk 'NR>1 {print $1}')
            if [[ ${#remaining_snaps[@]} -eq 0 ]]; then
                break
            fi
            info "Removal pass $pass..."
            for snap in "${remaining_snaps[@]}"; do
                info "Removing $snap..."
                run_privileged snap remove "$snap" || warn "Could not remove $snap, maybe required by another snap."
            done
        done

        info "Stopping and disabling snap services..."
        run_privileged systemctl stop snapd || warn "Failed to stop snapd (may not be running)"
        run_privileged systemctl disable snapd || warn "Failed to disable snapd (may not be installed)"
    else
        warn "snap command not found; snapd already absent."
    fi

    info "Purging snapd package..."
    run_privileged apt purge snapd -y || warn "Failed to purge snapd (you may need to remove manually)"

    info "Cleaning leftover snap directories..."
    rm -rf ~/snap
    run_privileged rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd

    ok "Snap and all its packages removed."
}

# Allow running standalone or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_snap_removal_interactive
fi
