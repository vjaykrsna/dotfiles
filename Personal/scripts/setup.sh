#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- CONFIG & UTILITY ---
start_dir=$(pwd)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; } # No exit here, setup.sh handles loop

# --- SCRIPT CONTEXT ---
# Ensures that scripts are run from the dotfiles root directory
with_dotfiles_root() {
    pushd "$(dirname "$0")/.." > /dev/null
    "$@"
    popd > /dev/null
}

# Source the installer functions which contain the core logic
source "$(dirname "$0")/installer.sh"

# --- DEPENDENCY CHECKS ---
check_basic_dependencies() {
    info "Checking basic dependencies..."
    local deps=(git curl jq git-lfs)
    local missing=()
    for dep in "${deps[@]}"; do
        ! command -v "$dep" &> /dev/null && missing+=("$dep")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing dependencies: ${missing[*]}"
        error "Please install: sudo apt install ${missing[*]}"
        exit 1
    fi
    ok "Basic dependencies satisfied."
}

# --- AUTOMATED FULL SETUP ---
run_all_setup() {
    info "--- 🚀 Starting Automated Full System Setup ---"
    check_basic_dependencies

    # Core system installation
    with_dotfiles_root run_preinstall
    with_dotfiles_root install_system_packages
    with_dotfiles_root setup_language_environment
    with_dotfiles_root install_language_packages
    with_dotfiles_root setup_shell_environment
    with_dotfiles_root run_nvidia_setup || warn "NVIDIA setup skipped or failed."
    with_dotfiles_root run_system_fixes
    with_dotfiles_root configure_system
    with_dotfiles_root run_post_install
    with_dotfiles_root run_nerd_fonts_installer

    # Additional tools and cleanup
    info "--- Installing CLI Tools ---"
    echo -e "123\nq" | with_dotfiles_root run_cli_installer # Install all tools (1,2,3), then quit
    info "--- Removing Snap Packages ---"
    echo "y" | with_dotfiles_root run_snap_removal # Auto-confirm snap removal

    # Restore configurations (for target machine setup)
    info "--- Restoring GNOME Settings ---"
    echo "2" | "$SCRIPT_DIR/gnome-settings.sh" # Auto-select restore mode
    info "--- Installing GNOME Extensions ---"
    echo "2" | "$SCRIPT_DIR/gnome-extensions.sh" # Auto-select install mode

    ok "--- ✅ Automated Full System Setup Complete ---"
}

# --- WRAPPER FUNCTIONS for scripts ---
run_update_pkgs() {
    info "--- Updating package lists ---"
    "$SCRIPT_DIR/package-sync.sh"
}

run_gnome_settings() {
    info "--- GNOME Settings Management ---"
    "$SCRIPT_DIR/gnome-settings.sh" interactive
}

run_gnome_extensions() {
    info "--- GNOME Extensions Management ---"
    "$SCRIPT_DIR/gnome-extensions.sh" interactive
}

run_system_sync() {
    info "--- System Configuration Management ---"
    "$SCRIPT_DIR/system-sync.sh" interactive
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
