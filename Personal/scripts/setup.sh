#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- CONFIG & UTILITY ---
start_dir=$(pwd)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
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
	pushd "$(dirname "$0")/.." >/dev/null
	"$@"
	popd >/dev/null
}

# Source the installer functions which contain the core logic
source "$(dirname "$0")/installer.sh"

# --- DEPENDENCY CHECKS ---
check_basic_dependencies() {
	info "Checking basic dependencies..."
	local deps=(git curl jq git-lfs)
	local missing=()
	for dep in "${deps[@]}"; do
		! command -v "$dep" &>/dev/null && missing+=("$dep")
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
    ok "--- ✅ Automated Full System Setup Complete ---"
}

# --- WRAPPER FUNCTIONS for scripts ---
run_update_pkgs() {
    info "--- Updating package lists ---"
    "$SCRIPT_DIR/update_pkgs.sh"
}

run_gnome_sync_dump() {
    info "--- Dumping GNOME settings ---"
    "$SCRIPT_DIR/gnome-settings.sh" dump
}

run_gnome_sync_load() {
    info "--- Loading GNOME settings ---"
    "$SCRIPT_DIR/gnome-settings.sh" load
}

run_gnome_extensions_save() {
    info "--- Saving GNOME extensions list ---"
    "$SCRIPT_DIR/gnome-extensions.sh" save
}

run_gnome_extensions_install() {
    info "--- Installing GNOME extensions ---"
    "$SCRIPT_DIR/gnome-extensions.sh" install
}

run_system_sync_save() {
    info "--- Saving system configurations ---"
    "$SCRIPT_DIR/system-sync.sh" save
}

run_system_sync_diff() {
    info "--- Diffing system configurations ---"
    "$SCRIPT_DIR/system-sync.sh" diff
}

# --- INTERACTIVE MENU ---
show_menu() {
	echo -e "
${BLUE}=====================================${NC}
 ${YELLOW}Dotfiles Management Utility${NC}
${BLUE}=====================================${NC}
 ${GREEN}AUTOMATED${NC}
   a. Run Automated Full Setup
 ${GREEN}PRE-INSTALLATION${NC}
   1. Pre-Install System Setup
 ${GREEN}SYSTEM SETUP${NC}
   2. Install System Packages
   3. Setup Language Environment
   4. Install Language Packages
   5. Setup Shell Environment (zinit + starship)
 
 ${GREEN}HARDWARE & MAINTENANCE${NC}
   6. Setup NVIDIA GPU
   7. Apply System Fixes
   8. Install CLI Tools (Interactive)
   9. Configure System (RAM + Power)
  10. Run Post-Install Configuration
  11. Install Nerd Fonts

 ${GREEN}DOTFILES & SETTINGS SYNC${NC}
  13. Update Package Lists (run on source machine)
  14. DUMP GNOME Settings (run on source machine)
  15. LOAD GNOME Settings (run on target machine)
  16. SAVE GNOME Extensions List (run on source machine)
  17. INSTALL GNOME Extensions (run on target machine)
  18. SAVE System Configs (crontab, fstab, hosts)
  19. DIFF System Configs

 ${RED}MAINTENANCE${NC}
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
    [14]=run_gnome_sync_dump
    [15]=run_gnome_sync_load
    [16]=run_gnome_extensions_save
    [17]=run_gnome_extensions_install
    [18]=run_system_sync_save
    [19]=run_system_sync_diff
)

# --- MAIN LOGIC ---
main_interactive() {
    check_basic_dependencies
    while true; do
        show_menu
        read -r choice

        if [[ "$choice" =~ ^[qQ]$ ]]; then
            info "Exiting."
            break
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
