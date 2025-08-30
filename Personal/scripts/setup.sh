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
 ${GREEN}QUICK SETUP${NC}
    0. Complete Setup (Fresh Install)

  ${GREEN}SHELL ENVIRONMENT${NC}
    1. Setup Shell Environment (zinit + starship)

  ${GREEN}PACKAGES & TOOLS${NC}
    2. Install System Packages
    3. Setup Language Environment
    4. Install Language Packages

  ${GREEN}CONFIGURATION${NC}
    5. Initialize Git LFS

  ${GREEN}PRE-SETUP${NC}
   -1. Pre-Install System Setup
   -2. Remove Snap Packages

  ${GREEN}HARDWARE & MAINTENANCE${NC}
   13. Setup NVIDIA GPU
   14. Apply System Fixes
   15. Install CLI Tools
   16. Configure RAM (ZRAM + Swap)

  ${GREEN}q. Quit${NC}
${BLUE}=====================================${NC}"
    echo -n -e "${YELLOW}Enter your choice: ${NC}"
}

# ===============================
# MENU ACTIONS
# ===============================
declare -A actions=(
    [0]=complete_setup
    [1]=setup_shell_environment
    [2]=install_system_packages
    [3]=setup_language_environment
    [4]=install_language_packages
    [5]=init_git_lfs
    [13]=run_nvidia_setup
    [14]=run_system_fixes
    [15]=run_cli_installer
    [16]=configure_ram
    [-1]=run_preinstall
    [-2]=run_snap_removal
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

    # Confirm full setup
    if [[ "$choice" == "0" ]]; then
        read -rp "⚠️  Complete Setup will run everything. Continue? (y/N) " ans
        [[ "$ans" != [yY] ]] && continue
    fi

    if [[ -n "${actions[$choice]:-}" ]]; then
        with_dotfiles_root "${actions[$choice]}"
    else
        error "Invalid option. Try again."
    fi
    echo
done

cd "$start_dir"
