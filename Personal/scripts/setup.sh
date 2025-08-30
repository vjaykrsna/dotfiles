#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================
# COLORS & LOGGING
# ===============================
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}› $*${NC}"; }
warn()  { echo -e "${YELLOW}› $*${NC}"; }
error() { echo -e "${RED}› $*${NC}"; }

# ===============================
# UTILITY
# ===============================
start_dir=$(pwd)
with_dotfiles_root() { pushd "$(dirname "$0")/.." >/dev/null; "$@"; popd >/dev/null; }

source ./scripts/installer.sh  # installer functions

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

# ===============================
# MENU DISPLAY
# ===============================
show_menu() {
    echo -e "
${BLUE}=====================================${NC}
 ${YELLOW}Dotfiles Management Utility${NC}
${BLUE}=====================================${NC}
 ${GREEN}PRE-INSTALLATION${NC}
   1. Pre-Install System Setup
   2. Remove Snap Packages

 ${GREEN}SYSTEM SETUP${NC}
   3. Install System Packages
   4. Setup Language Environment
   5. Install Language Packages
   6. Setup Shell Environment (zinit + starship)

 ${GREEN}HARDWARE & MAINTENANCE${NC}
   7. Setup NVIDIA GPU
   8. Apply System Fixes
   9. Install CLI Tools
  10. Configure System (RAM + Power)

  ${GREEN}q. Quit${NC}
${BLUE}=====================================${NC}"
    echo -n -e "${YELLOW}Enter your choice: ${NC}"
}

# ===============================
# MENU ACTIONS
# ===============================
declare -A actions=(
    [1]=run_preinstall
    [2]=run_snap_removal
    [3]=install_system_packages
    [4]=setup_language_environment
    [5]=install_language_packages
    [6]=setup_shell_environment
    [7]=run_nvidia_setup
    [8]=run_system_fixes
    [9]=run_cli_installer
    [10]=configure_system
)

# ===============================
# MAIN LOOP
# ===============================
check_basic_dependencies

while true; do
    show_menu
    read -r choice

    # Exit options
    if [[ "$choice" =~ ^[qQ]$ ]]; then
        log "Exiting."
        break
    fi


    if [[ -n "${actions[$choice]:-}" ]]; then
        with_dotfiles_root "${actions[$choice]}"
    else
        error "Invalid option. Try again."
    fi
    echo
done

cd "$start_dir"
