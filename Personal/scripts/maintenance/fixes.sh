#!/usr/bin/env bash
# fixes.sh - Run common post-installation fixes
# Usage: ./fixes.sh [all|input|udev|sssd|check] [username]
# Example: sudo ./fixes.sh input myuser
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh" # For logging functions
source "$SCRIPT_DIR/../utils/utils.sh" # For utility functions

# Trap errors to log them
trap 'error "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# --- USER HANDLING ---
USERNAME="${2:-${SUDO_USER:-$USER}}"

# --- FIX: Input-Remapper ---
fix_input_remapper() {
    info "Ensuring idempotent configuration for input-remapper for $USERNAME..."

    # 1. Ensure user is in the correct groups
    local updated=false
    run_privileged groupadd -f input
    for g in input video audio; do
        if ! id -nG "$USERNAME" | grep -qw "$g"; then
            run_privileged usermod -a -G "$g" "$USERNAME"
            ok "Added $USERNAME to group '$g'"
            updated=true
        fi
    done
    if [[ "$updated" == true ]]; then
        warn "User must log out and back in for group changes to take full effect"
    fi

    # 2. Ensure systemd service override is correct
    local override_dir="/etc/systemd/system/input-remapper-daemon.service.d"
    local override_file="$override_dir/override.conf"
    run_privileged mkdir -p "$override_dir"
    echo -e "[Service]\nUser=$USERNAME" | run_privileged tee "$override_file" > /dev/null

    # 3. Ensure udev rule for /dev/uinput permissions is correct
    local udev_rule_file="/etc/udev/rules.d/70-input-remapper-permissions.rules"
    info "Ensuring correct udev rule for input device permissions..."
    echo 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' | run_privileged tee "$udev_rule_file" > /dev/null

    # 4. Reload daemons and restart the service
    run_privileged systemctl daemon-reload
    run_privileged udevadm control --reload-rules
    run_privileged udevadm trigger
    run_privileged systemctl restart input-remapper-daemon.service 2> /dev/null || true

    ok "input-remapper configuration is up to date."
}

# --- FIX: Udev rules ---
fix_udev() {
    info "Refreshing udev rules..."
    run_privileged udevadm control --reload-rules
    run_privileged udevadm trigger
    ok "udev rules refreshed"
}

# --- FIX: Disable SSSD ---
disable_sssd() {
    info "Disabling SSSD services..."
    run_privileged systemctl disable --now sssd.service sssd-kcm.service 2> /dev/null || true
    ok "SSSD services disabled"
}

# --- Verifications ---
check_groups() {
    info "Checking groups..."
    for g in input video audio; do
        if id -nG "$USERNAME" | grep -qw "$g"; then
            ok "$g group OK"
        else
            warn "$g group missing"
        fi
    done
}

# --- CLI ---
case "${1:-all}" in
input) fix_input_remapper ;;
udev) fix_udev ;;
sssd) disable_sssd ;;
check)
    check_groups
    ;;
all | "")
    fix_input_remapper
    fix_udev
    disable_sssd
    ;;
*)
    echo "Usage: $0 {all|input|udev|sssd|check} [username]"
    exit 1
    ;;
esac
