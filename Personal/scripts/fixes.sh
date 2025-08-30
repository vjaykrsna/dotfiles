#!/bin/bash
# fixes.sh - Post-Installation Common Fixes

set -euo pipefail
IFS=$'\n\t'

# --- COLORS ---
BLUE='\033[0;34m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "$1$2${NC}"; }
info() { log "$BLUE" "ℹ️  $1"; }
ok()   { log "$GREEN" "✅ $1"; }
warn() { log "$YELLOW" "⚠️  $1"; }
err()  { log "$RED" "❌ $1"; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }

USERNAME=${2:-$(whoami)}

# --- FIX 1: Input-Remapper groups ---
fix_input_groups() {
    info "Fixing input-remapper groups for $USERNAME..."
    run_privileged groupadd -f input
    for g in input video audio; do
        if ! groups "$USERNAME" | grep -qw "$g"; then
            run_privileged usermod -a -G "$g" "$USERNAME"
            ok "Added $USERNAME to $g"
        fi
    done
    run_privileged systemctl restart input-remapper 2>/dev/null || true
}

# --- FIX 2: Dock extension conflicts ---
fix_extensions() {
    info "Cleaning up dock extensions..."
    local EXTENSIONS=(
        "ubuntu-dock@ubuntu.com"
        "dash-to-dock@micxgx.gmail.com"
        "azizapp@azizapp"
        "vertical-overview@RensAlthuis.github.com"
    )
    for ext in "${EXTENSIONS[@]}"; do
        gnome-extensions disable "$ext" 2>/dev/null || true
    done
    ok "Dock extensions cleaned"
}

# --- FIX 3: Cron environment (optional) ---
fix_cron() {
    info "Ensuring cron EXTRA_OPTS is defined..."
    if ! grep -q "EXTRA_OPTS" /etc/environment; then
        echo 'EXTRA_OPTS=""' | run_privileged tee -a /etc/environment > /dev/null
        ok "Added EXTRA_OPTS to /etc/environment"
        run_privileged systemctl reload cron 2>/dev/null || true
    else
        info "EXTRA_OPTS already present"
    fi
}

# --- FIX 4: Udev rules ---
fix_udev() {
    info "Refreshing udev rules..."
    run_privileged udevadm control --reload-rules
    run_privileged udevadm trigger
    ok "udev rules refreshed"
}

# --- Verifications ---
check_groups() {
    info "Checking groups..."
    for g in input video audio; do
        if groups "$USERNAME" | grep -qw "$g"; then
            ok "$g group OK"
        else
            warn "$g group missing"
        fi
    done
}

check_extensions() {
    info "Checking dock extensions..."
    local count
    count=$(gnome-extensions list --enabled | grep -c dock || true)
    if [ "$count" -gt 1 ]; then
        err "Multiple dock extensions enabled!"
    else
        ok "Dock extensions OK"
    fi
}

# --- CLI ---
case "$1" in
    input) fix_input_groups ;;
    extensions) fix_extensions ;;
    cron) fix_cron ;;
    udev) fix_udev ;;
    check) check_groups; check_extensions ;;
    all|"") fix_input_groups; fix_extensions; fix_cron; fix_udev ;;
    *) echo "Usage: $0 {all|input|extensions|cron|udev|check}"; exit 1 ;;
esac
