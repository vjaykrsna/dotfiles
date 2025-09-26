#!/usr/bin/env bash
# fixes.sh - Run common post-installation fixes
# Usage: ./fixes.sh [all|input|udev|sssd|check] [username]
# Example: sudo ./fixes.sh input myuser
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh" # For logging functions
source "$SCRIPT_DIR/../utils/utils.sh" # For utility functions

# Trap errors to log them and exit via fatal()
set_robust_error_handling

# --- USER HANDLING ---
USERNAME="${2:-${SUDO_USER:-$USER}}"

# --- FIX: Input-Remapper ---
fix_input_remapper() {
    info "Ensuring idempotent configuration for input-remapper for $USERNAME..."

    # 1. Ensure user is in the correct groups
    local updated=false
    ensure_group_exists input
    for g in input video audio; do
        if ! ensure_user_in_group "$USERNAME" "$g"; then
            ok "Added $USERNAME to group '$g'"
            updated=true
        fi
    done
    if [[ "$updated" == true ]]; then
        warn "User must log out and back in for group changes to take full effect"
    fi

    # 2. Ensure systemd service override is correct
        if ensure_systemd_override "input-remapper-daemon.service" "[Service]\nUser=$USERNAME"; then
            info "Systemd override installed for input-remapper"
        else
            warn "Systemd override may not have been installed correctly"
        fi

    # 3. Ensure udev rule for /dev/uinput permissions is correct
    local udev_rule_file="/etc/udev/rules.d/70-input-remapper-permissions.rules"
    info "Ensuring correct udev rule for input device permissions..."
        if ensure_udev_rule "$udev_rule_file" 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"'; then
            # Reload daemons only if write succeeded
            run_privileged systemctl daemon-reload || warn "systemctl daemon-reload failed"
            run_privileged udevadm control --reload-rules || warn "udevadm control --reload-rules failed"
            run_privileged udevadm trigger || warn "udevadm trigger failed"
            ok "input-remapper configuration is up to date."
        else
            error "Failed to install udev rule for input-remapper; skipping reloads"
        fi

    # 4. Reload daemons
    run_privileged systemctl daemon-reload
    run_privileged udevadm control --reload-rules
    run_privileged udevadm trigger

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

# --- FIX: Docker Group ---
fix_docker_group() {
    # Ensure the docker group exists (idempotent)
    run_privileged groupadd -f docker

    if command -v docker &>/dev/null; then
        info "Ensuring $USERNAME is in docker group..."
        if ! id -nG "$USERNAME" | grep -qw docker; then
            run_privileged usermod -aG docker "$USERNAME"
            ok "Added $USERNAME to docker group"
            warn "User must log out and back in for group changes to take full effect"
        else
            ok "docker group OK"
        fi
    else
        info "docker group present but Docker binary not found; group created/ensured"
    fi
}

# --- Verifications ---
check_groups() {
    info "Checking groups..."
    for g in input video audio docker; do
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
docker) fix_docker_group ;;
check)
    check_groups
    ;;
all | "")
    fix_input_remapper
    fix_udev
    disable_sssd
    fix_docker_group
    ;;
*)
    fatal "Usage: $0 {all|input|udev|sssd|docker|check} [username]"
    ;;
esac
