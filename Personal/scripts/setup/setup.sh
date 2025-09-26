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

# Source the installer functions which contain the core logic
source "$SCRIPT_DIR/../utils/installer.sh"

# Trap errors to log them and exit via fatal()
set_robust_error_handling

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
        info "--- $desc ---"
        with_dotfiles_root "$func" || warn "$desc failed"
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

# --- INTERACTIVE MENU ---
show_menu() {
    echo -e "
${BLUE}=====================================${NC}
 ${YELLOW}Dotfiles Management Utility${NC}
${BLUE}=====================================${NC}
 ${GREEN}🚀 AUTOMATED${NC}
   a. Run Automated Full Setup

 ${GREEN}⚙️  SYSTEM SETUP${NC}
   1. Pre-Install System Setup
   2. Install System Packages
   3. Setup Language Environment
   4. Install Language Packages
   5. Setup Shell Environment (zinit + starship)

 ${GREEN}🔧 HARDWARE & MAINTENANCE${NC}
   6. Setup NVIDIA GPU
   7. Apply System Fixes
   8. Install CLI Tools (Interactive)
   9. Configure System (RAM + Power)
  10. Run Post-Install Configuration
  11. Install Nerd Fonts

 ${GREEN}📦 PACKAGE & SYSTEM SYNC${NC}
  13. Update Package Lists (source machine)
  14. GNOME Settings (backup/restore)
  15. GNOME Extensions (backup/install)
  16. System Configs (backup/compare)

 ${RED}🧹 MAINTENANCE${NC}
  12. Remove Snap Packages (Interactive)

  ${GREEN}q. Quit${NC}
${BLUE}=====================================${NC}"
    echo -n -e "${YELLOW}Enter your choice: ${NC}"
}

# --- MENU ACTIONS ---
declare -A actions=(
    [a]=run_all_setup
    [1]=run_preinstall
    [2]=install_system_packages
    [3]=setup_language_environment
    [4]=install_language_packages
    [5]=setup_shell_environment
    [6]=run_nvidia_setup
    [7]=run_system_fixes
    [8]=run_cli_installer
    [9]=configure_system
    [10]=run_post_install
    [11]=run_nerd_fonts_installer
    [12]=run_snap_removal
    [13]=run_update_pkgs
    [14]=run_gnome_settings
    [15]=run_gnome_extensions
    [16]=run_system_sync
)

# --- MAIN LOGIC ---
main_interactive() {
    check_basic_dependencies
    ensure_runtime_tmpdir
    local show_full_menu=true
    while true; do
        if [[ "$show_full_menu" == true ]]; then
            show_menu
            show_full_menu=false
        else
            echo -n -e "${YELLOW}Enter your choice (or 'm' for menu): ${NC}"
        fi
        read -r choice

        if [[ "$choice" =~ ^[qQ]$ ]]; then
            info "Exiting."
            break
        fi

        if [[ "$choice" =~ ^[mM]$ ]]; then
            show_full_menu=true
            continue
        fi

        if [[ -n "$choice" ]]; then
            if [[ -n "${actions[$choice]:-}" ]]; then
                # For 'a', run directly without with_dotfiles_root as it handles it internally
                if [[ "$choice" == "a" ]]; then
                    "${actions[$choice]}"
                else
                    with_dotfiles_root "${actions[$choice]}" || true
                fi
            else
                error "Invalid option. Try again."
            fi
        fi
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
