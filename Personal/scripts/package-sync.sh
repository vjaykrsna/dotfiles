#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- CONFIGURATION ---
# The directory where package lists are stored.
SAVE_DIR="$(dirname "$0")/packages"
mkdir -p "$SAVE_DIR"

# --- UTILITY FUNCTIONS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }

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
        cargo install --list | awk '$1 ~ /^[a-zA-Z0-9_-]+$/ {print $1}' > "$SAVE_DIR/cargo-crates.txt"
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
