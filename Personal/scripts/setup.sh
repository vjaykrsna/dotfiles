#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- CONFIG & UTILITY ---
start_dir=$(pwd)
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() { echo -e "${RED}❌ $*${NC}"; } # No exit here, setup.sh handles loop
with_dotfiles_root() {
	pushd "$(dirname "$0")/.." >/dev/null
	"$@"
	popd >/dev/null
}

source "$(dirname "$0")/installer.sh" # installer functions

ensure_file_nonempty() { [[ -f "$1" && -s "$1" ]]; }

check_basic_dependencies() {
	log "Checking basic dependencies..."
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
	log "Basic dependencies satisfied."
}

validate_environment() {
	check_basic_dependencies
}

# --- MENU DISPLAY ---
show_menu() {
	echo -e "
${BLUE}=====================================${NC}
 ${YELLOW}Dotfiles Management Utility${NC}
${BLUE}=====================================${NC}
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

 ${RED}MAINTENANCE${NC}
  12. Remove Snap Packages (Interactive)

  ${GREEN}q. Quit${NC}
${BLUE}=====================================${NC}"
	echo -n -e "${YELLOW}Enter your choice: ${NC}"
}

# --- MENU ACTIONS ---
declare -A actions=(
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
)

# --- MAIN LOOP ---
check_basic_dependencies

while true; do
	show_menu
	read -r choice

	if [[ "$choice" =~ ^[qQ]$ ]]; then
		log "Exiting."
		break
	fi

	if [[ -n "$choice" ]]; then
		if [[ -n "${actions[$choice]:-}" ]]; then
			with_dotfiles_root "${actions[$choice]}" || true
		else
			error "Invalid option. Try again."
		fi
	fi
	echo
done

cd "$start_dir"
