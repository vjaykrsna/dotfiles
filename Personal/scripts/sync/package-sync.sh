#!/usr/bin/env bash
# package-sync.sh - Update saved package lists (apt, flatpak, snap, npm, pipx, cargo, bun)
# Usage: ./package-sync.sh
# Example: ./package-sync.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/bootstrap.sh"

# --- CONFIGURATION ---
# Configuration: central tools/packages directory for package lists
SAVE_DIR="$SCRIPT_DIR/../tools/packages"
mkdir -p "$SAVE_DIR"

# --- PACKAGE LIST GENERATORS ---

save_apt() {
    save_resource "APT packages" "$SAVE_DIR/apt.txt" 'apt-mark showmanual'
}

save_flatpak() {
    if command -v flatpak &> /dev/null; then
        save_resource "Flatpak packages" "$SAVE_DIR/flatpak.txt" 'flatpak list --app --columns=application'
    fi
}

save_snap() {
    if command -v snap &> /dev/null; then
        save_resource "Snap packages" "$SAVE_DIR/snap.txt" 'snap list | tail -n +2 | awk "{print \$1}"'
    fi
}

save_npm() {
    if command -v npm &> /dev/null; then
        save_resource "npm globals" "$SAVE_DIR/npm-globals.txt" 'npm list -g --depth=0 | awk -F " " "/@/ {print \$2}" | sed "s/@[^@]*$/@latest/"'
    fi
}

save_pipx() {
    if command -v pipx &> /dev/null; then
        save_resource "pipx packages" "$SAVE_DIR/pipx.txt" 'pipx list --short | awk "{print \$1}"'
    fi
}

save_cargo() {
    if command -v cargo &> /dev/null; then
        save_resource "Cargo crates" "$SAVE_DIR/cargo-crates.txt" 'cargo install --list | awk "$1 ~ /^[a-zA-Z0-9_.-]+$/ {print \$1}"'
    fi
}

save_bun() {
    if command -v bun &> /dev/null; then
        save_resource "Bun globals" "$SAVE_DIR/bun-globals.txt" 'bun pm -g ls --bare 2>/dev/null | cut -d"@" -f1'
    fi
}

# --- LOAD FUNCTION ---
load_packages() {
    info "--- Loading Packages from Saved Lists ---"
    source "$SCRIPT_DIR/../utils/package_installer.sh"
    [[ -f "$SAVE_DIR/apt.txt" ]] && install_packages_from_file "$SAVE_DIR/apt.txt" run_privileged apt-get install -y -q --no-install-recommends
    [[ -f "$SAVE_DIR/flatpak.txt" ]] && flatpak_cmd=(flatpak install -y --noninteractive); [[ "$(id -u)" -eq 0 ]] && flatpak_cmd+=(--system); install_packages_from_file "$SAVE_DIR/flatpak.txt" "${flatpak_cmd[@]}"
    [[ -f "$SAVE_DIR/npm-globals.txt" ]] && install_packages_from_file "$SAVE_DIR/npm-globals.txt" npm install -g
    [[ -f "$SAVE_DIR/cargo-crates.txt" ]] && install_packages_from_file "$SAVE_DIR/cargo-crates.txt" cargo install
    [[ -f "$SAVE_DIR/bun-globals.txt" ]] && install_packages_from_file "$SAVE_DIR/bun-globals.txt" bun install -g
    [[ -f "$SAVE_DIR/pipx.txt" ]] && install_packages_from_file "$SAVE_DIR/pipx.txt" pipx install
    ok "--- Package load complete ---"
}

# --- DIFF FUNCTION ---
diff_packages() {
    info "--- Diffing Saved vs Installed Packages ---"
    [[ -f "$SAVE_DIR/apt.txt" ]] && diff_resource "APT" "$SAVE_DIR/apt.txt" 'apt-mark showmanual'
    command -v flatpak &> /dev/null && [[ -f "$SAVE_DIR/flatpak.txt" ]] && diff_resource "Flatpak" "$SAVE_DIR/flatpak.txt" 'flatpak list --app --columns=application'
    command -v snap &> /dev/null && [[ -f "$SAVE_DIR/snap.txt" ]] && diff_resource "Snap" "$SAVE_DIR/snap.txt" 'snap list | tail -n +2 | awk "{print \$1}"'
    command -v npm &> /dev/null && [[ -f "$SAVE_DIR/npm-globals.txt" ]] && diff_resource "npm" "$SAVE_DIR/npm-globals.txt" 'npm list -g --depth=0 | awk -F " " "/@/ {print \$2}" | sed "s/@[^@]*$/@latest/"'
    command -v pipx &> /dev/null && [[ -f "$SAVE_DIR/pipx.txt" ]] && diff_resource "pipx" "$SAVE_DIR/pipx.txt" 'pipx list --short | awk "{print \$1}"'
    command -v cargo &> /dev/null && [[ -f "$SAVE_DIR/cargo-crates.txt" ]] && diff_resource "Cargo" "$SAVE_DIR/cargo-crates.txt" 'cargo install --list | awk "$1 ~ /^[a-zA-Z0-9_.-]+$/ {print \$1}"'
    command -v bun &> /dev/null && [[ -f "$SAVE_DIR/bun-globals.txt" ]] && diff_resource "Bun" "$SAVE_DIR/bun-globals.txt" 'bun pm -g ls --bare 2>/dev/null | cut -d"@" -f1'
    ok "--- Diff complete ---"
}

# --- MAIN EXECUTION ---
case "${1:-save}" in
save)
    info "--- Starting Package List Update ---"
    save_apt
    save_flatpak
    save_snap
    save_npm
    save_pipx
    save_cargo
    save_bun
    ok "--- All package lists have been updated successfully! ---"
    ;;
load)
    load_packages
    ;;
diff)
    diff_packages
    ;;
*)
    fatal "Usage: $0 {save|load|diff}"
    ;;
esac
