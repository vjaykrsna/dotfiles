#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# --- CONFIG & UTILITY ---
start_dir=$(pwd)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- SCRIPT CONTEXT ---
# Ensures that scripts are run from the dotfiles root directory
with_dotfiles_root() {
    pushd "$(dirname "$0")/.." > /dev/null
    "$@"
    popd > /dev/null
}

source "$SCRIPT_DIR/../utils/bootstrap.sh"
source "$SCRIPT_DIR/../utils/package_installer.sh"
source "$SCRIPT_DIR/../utils/language_installer.sh"

safe_run() {
    local func="$1"
    local desc="${2:-$func}"
    info "--- $desc ---"
    with_dotfiles_root "$func" || warn "$desc failed"
}

# --- SYSTEM FIXES ---
run_system_fixes() {
    info "--- Running System Fixes ---"
    bash "$SCRIPT_DIR/../maintenance/fixes.sh" all || fatal "System fixes failed"
    info "--- System Fixes Complete ---"
}

# --- CLI INSTALLER ---
run_cli_installer() {
    info "--- Running CLI Tools Installer ---"
    if source "$SCRIPT_DIR/../tools/cli.sh" && run_cli_installer_interactive; then
        :
    else
        warn "CLI installer encountered issues"
    fi
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
    if source "$SCRIPT_DIR/../maintenance/snap-removal.sh" && run_snap_removal_interactive; then
        :
    else
        warn "Snap removal encountered issues"
    fi
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

# --- AUTOMATED FULL SETUP ---
run_all_setup() {
    info "--- 🚀 Starting Automated Full System Setup ---"
    check_basic_dependencies
    ensure_runtime_tmpdir
    ensure_sudo

    local steps=(
        "run_preinstall:Pre-install system setup"
        "install_system_packages:System package installation"
        "setup_language_environment:Language environment setup"
        "install_language_packages:Language package installation"
        "setup_shell_environment:Shell environment setup"
        "run_nvidia_setup:NVIDIA GPU setup"
        "run_system_fixes:System fixes application"
        "configure_system:System configuration"
        "run_post_install:Post-install configuration"
        "run_nerd_fonts_installer:Nerd fonts installation"
    )
    local total_steps=${#steps[@]} current_step=0

    # Core system installation
    for step in "${steps[@]}"; do
        ((++current_step))
        local func=${step%%:*} desc=${step#*:}
        show_progress $((current_step-1)) "$total_steps" "Setup"
        safe_run "$func" "$desc"
    done
    show_progress "$total_steps" "$total_steps" "Setup"

    # Additional tools and cleanup
    info "--- Installing CLI Tools ---"
    with_dotfiles_root run_cli_installer --all || warn "CLI install partial"

    info "--- Removing Snap Packages ---"
    with_dotfiles_root run_snap_removal || warn "Snap removal skipped"

    # Restore configurations (for target machine setup)
    info "--- Restoring GNOME Settings ---"
    bash "$SCRIPT_DIR/../sync/gnome-settings.sh" load || warn "GNOME settings load skipped"
    info "--- Installing GNOME Extensions ---"
    bash "$SCRIPT_DIR/../sync/gnome-extensions.sh" install || warn "Extensions install skipped"

    ok "--- ✅ Automated Full System Setup Complete ---"
}

# --- WRAPPER FUNCTIONS for scripts ---
run_update_pkgs() {
    info "--- Updating package lists ---"
    bash "$SCRIPT_DIR/../sync/package-sync.sh" || fatal "Package sync failed"
}

run_gnome_settings() {
    info "--- GNOME Settings Management ---"
    bash "$SCRIPT_DIR/../sync/gnome-settings.sh" interactive || warn "GNOME settings management failed"
}

run_gnome_extensions() {
    info "--- GNOME Extensions Management ---"
    bash "$SCRIPT_DIR/../sync/gnome-extensions.sh" interactive || warn "GNOME extensions management failed"
}

run_system_sync() {
    info "--- System Configuration Management ---"
    bash "$SCRIPT_DIR/../sync/system-sync.sh" interactive || warn "System sync management failed"
}

# --- MAIN LOGIC ---
main_interactive() {
    check_basic_dependencies
    ensure_runtime_tmpdir
    local options=(
        "Run Automated Full Setup"
        "Pre-Install System Setup"
        "Install System Packages"
        "Setup Language Environment"
        "Install Language Packages"
        "Setup Shell Environment (zinit + starship)"
        "Setup NVIDIA GPU"
        "Apply System Fixes"
        "Install CLI Tools (Interactive)"
        "Configure System (RAM + Power)"
        "Run Post-Install Configuration"
        "Install Nerd Fonts"
        "Remove Snap Packages (Interactive)"
        "Update Package Lists (source machine)"
        "GNOME Settings (backup/restore)"
        "GNOME Extensions (backup/install)"
        "System Configs (backup/compare)"
        "Quit"
    )
    local actions_list=(
        run_all_setup
        run_preinstall
        install_system_packages
        setup_language_environment
        install_language_packages
        setup_shell_environment
        run_nvidia_setup
        run_system_fixes
        run_cli_installer
        configure_system
        run_post_install
        run_nerd_fonts_installer
        run_snap_removal
        run_update_pkgs
        run_gnome_settings
        run_gnome_extensions
        run_system_sync
    )
    while true; do
        echo -e "${YELLOW}Dotfiles Management Utility${NC}"
        select opt in "${options[@]}"; do
            if [[ $REPLY == "${#options[@]}" ]]; then
                info "Exiting."
                break 2
            elif [[ $REPLY -ge 1 && $REPLY -le ${#actions_list[@]} ]]; then
                local func="${actions_list[$((REPLY-1))]}"
                if [[ $func == "run_all_setup" ]]; then
                    "$func"
                else
                    safe_run "$func"
                fi
                break
            else
                error "Invalid option. Try again."
            fi
        done
        echo
    done
}

# --- SCRIPT ENTRYPOINT ---
if [[ "${1-}" == "all" ]]; then
    run_all_setup
else
    main_interactive
fi

cd "$start_dir"
