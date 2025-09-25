#!/usr/bin/env bash
# installer.sh - Top-level installer orchestrator
# Usage: sudo ./installer.sh
# Example: sudo ./installer.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utilities
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/utils.sh"
ensure_runtime_tmpdir

# Source modular components
source "$SCRIPT_DIR/package_installer.sh"
source "$SCRIPT_DIR/language_installer.sh"

# --- LANGUAGE ENVIRONMENT ---
# Language functions moved to language_installer.sh

# --- SYSTEM FIXES ---
run_system_fixes() {
    info "--- Running System Fixes ---"
    bash "$SCRIPT_DIR/../maintenance/fixes.sh" all || fatal "System fixes failed"
    info "--- System Fixes Complete ---"
}

# --- CLI INSTALLER ---
run_cli_installer() {
    info "--- Running CLI Tools Installer ---"
    source "$SCRIPT_DIR/../tools/cli.sh" && run_cli_installer_interactive || warn "CLI installer encountered issues"
    ok "--- CLI Tools Installation Complete ---"
}

# --- PRE-INSTALL ---
run_preinstall() {
    info "--- Running Pre-Install Setup ---"
    run_privileged bash "$SCRIPT_DIR/../setup/pre-install.sh" || fatal "Pre-install setup failed"
    info "--- Pre-Install Setup Complete ---"
}

# --- SNAP REMOVAL ---
run_snap_removal() {
    info "--- Running Snap Removal ---"
    source "$SCRIPT_DIR/../maintenance/snap-removal.sh" && run_snap_removal_interactive || warn "Snap removal encountered issues"
    ok "--- Snap Removal Complete ---"
}

# --- POST-INSTALL ---
run_post_install() {
    info "--- Running Post-Install ---"
    run_privileged bash "$SCRIPT_DIR/../setup/post-install.sh" || warn "Post-install encountered issues"
    ok "--- Post-Install Complete ---"
}

# --- SHELL ENVIRONMENT ---
setup_shell_environment() {
    setup_zinit_starship
}

# --- NVIDIA GPU SETUP ---
run_nvidia_setup() {
    info "--- Setting Up NVIDIA GPU ---"
    bash "$SCRIPT_DIR/../maintenance/nvidia.sh" || warn "NVIDIA setup encountered issues"
    info "--- NVIDIA GPU Setup Complete ---"
}

# --- SYSTEM CONFIGURATION ---
configure_system() {
    info "--- Configuring System (RAM + Power) ---"
    bash "$SCRIPT_DIR/../maintenance/myconfig.sh" || fatal "System configuration failed"
    info "--- System Configuration Complete ---"
}

# --- SHELL ENVIRONMENT (ZINIT/STARSHIP) ---
setup_zinit_starship() {
    info "--- Setting Up Shell Environment ---"
    local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [ ! -d "$ZINIT_HOME" ]; then
        warn "Installing Zinit..."
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi

    command -v starship > /dev/null && {
        warn "Setting up Starship prompt..."
        mkdir -p "$HOME/.config"
        info "Starship configuration ready."
    }

    if command -v fc-cache &> /dev/null; then
        warn "Rebuilding font cache..."
        fc-cache -fv
    else
        warn "Skipping font cache rebuild: fc-cache not found."
    fi
    info "--- Shell Environment Setup Complete ---"
}

# --- NERD FONTS ---
run_nerd_fonts_installer() {
    info "--- Running Nerd Fonts Installer ---"
    source "$SCRIPT_DIR/../tools/nerd-fonts.sh" && install_nerd_fonts
    ok "--- Nerd Fonts Installation Complete ---"
}
