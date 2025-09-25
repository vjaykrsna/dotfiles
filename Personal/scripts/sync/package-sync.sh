#!/usr/bin/env bash
# package-sync.sh - Update saved package lists (apt, flatpak, snap, npm, pipx, cargo, bun)
# Usage: ./package-sync.sh
# Example: ./package-sync.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them
trap 'error "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# --- CONFIGURATION ---
# Configuration: central tools/packages directory for package lists
SAVE_DIR="$SCRIPT_DIR/../tools/packages"
mkdir -p "$SAVE_DIR"

# --- PACKAGE LIST GENERATORS ---

save_apt() {
    info "Updating APT package list..."
    apt-mark showmanual > "$SAVE_DIR/apt.txt"
    ok "APT list updated."
}

save_flatpak() {
    if command -v flatpak &> /dev/null; then
        info "Updating Flatpak package list..."
        flatpak list --app --columns=application > "$SAVE_DIR/flatpak.txt"
        ok "Flatpak list updated."
    fi
}

save_snap() {
    if command -v snap &> /dev/null; then
        info "Updating Snap package list..."
        snap list | tail -n +2 | awk '{print $1}' > "$SAVE_DIR/snap.txt"
        ok "Snap list updated."
    fi
}

save_npm() {
    if command -v npm &> /dev/null; then
        info "Updating npm global package list..."
        npm list -g --depth=0 | awk -F ' ' '/@/ {print $2}' | sed 's/@[^@]*$/@latest/' > "$SAVE_DIR/npm-globals.txt"
        ok "npm list updated."
    fi
}

save_pipx() {
    if command -v pipx &> /dev/null; then
        info "Updating pipx package list..."
        pipx list --short | awk '{print $1}' > "$SAVE_DIR/pipx.txt"
        ok "pipx list updated."
    fi
}

save_cargo() {
    if command -v cargo &> /dev/null; then
        info "Updating Cargo crate list..."
        cargo install --list | awk '$1 ~ /^[a-zA-Z0-9_.-]+$/ {print $1}' > "$SAVE_DIR/cargo-crates.txt"
        ok "Cargo list updated."
    fi
}

save_bun() {
    if command -v bun &> /dev/null; then
        info "Updating Bun global package list..."
        bun pm -g ls --bare 2> /dev/null | cut -d'@' -f1 > "$SAVE_DIR/bun-globals.txt"
        ok "Bun list updated."
    fi
}

# --- MAIN EXECUTION ---
info "--- Starting Package List Update ---"
save_apt
save_flatpak
save_snap
save_npm
save_pipx
save_cargo
save_bun
ok "--- All package lists have been updated successfully! ---"
