#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- UTILITY FUNCTIONS ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() {
	echo -e "${RED}❌ $*${NC}"
	exit 1
} # Exit on error

ensure_file_nonempty() { [[ -f "$1" && -s "$1" ]]; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }
run_as_user() { [ "$EUID" -eq 0 ] && (ensure_user_context && "$@") || "$@"; }

ensure_user_context() {
	local target_user="${SUDO_USER:-$USER}"
	if [ "$EUID" -eq 0 ] && [ "$target_user" != "root" ]; then
		export HOME="/home/$target_user"
		cd "$HOME" || true
		warn "Switched context to user: $target_user"
	fi
}

load_language_env() {
	[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
	export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"
}

install_packages_from_file() {
	local file="$1" cmd="$2"
	if ensure_file_nonempty "$file"; then
		log "Installing from $file..."
		xargs -a "$file" -r --no-run-if-empty sh -c "$(typeset -f run_privileged); $cmd \"\$@\"" _
	fi
}

# --- SYSTEM PACKAGES ---
install_system_packages() {
	info "--- System Package Installation ---"

	[[ -f scripts/packages/custom.sh ]] && run_privileged bash scripts/packages/custom.sh

	warn "Updating package lists..."
	run_privileged apt-get update

	install_packages_from_file scripts/packages/apt.txt "run_privileged apt-get install -y --no-install-recommends"
	install_packages_from_file scripts/packages/flatpak.txt "flatpak install -y"
}

# --- LANGUAGE ENVIRONMENT ---
setup_nvm() {
	warn "Setting up NVM..."
	if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
		log "NVM already installed."
	else
		curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	fi

	export NVM_DIR="$HOME/.nvm"
	source "$NVM_DIR/nvm.sh" 2>/dev/null || true
	source "$NVM_DIR/bash_completion" 2>/dev/null || true

	command -v node >/dev/null || {
		warn "Installing Node.js..."
		nvm install node
		nvm use node
	}
}

setup_rust() {
	command -v cargo >/dev/null || {
		warn "Installing Rust..."
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		load_language_env
	}
}

setup_bun() {
	command -v bun >/dev/null || {
		warn "Installing Bun..."
		curl -fsSL https://bun.sh/install | bash
		load_language_env
	}
}

setup_pipx() {
	command -v pipx >/dev/null || {
		warn "Installing pipx..."
		python3 -m pip install --user pipx
		python3 -m pipx ensurepath
	}
}

setup_language_environment() {
	log "--- Setting Up Language Environment ---"
	setup_nvm
	setup_rust
	setup_bun
	setup_pipx
	log "--- Language Environment Setup Complete ---"
}

install_language_packages() {
	log "--- Installing Language Packages ---"
	run_as_user bash -c "
        export NVM_DIR=\"\$HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\"
        $(typeset -f load_language_env); load_language_env

        cd \"$PWD\"

        $(typeset -f ensure_file_nonempty)
        $(typeset -f install_packages_from_file)
        $(typeset -f log)
        log \"Installing npm global packages...\"

        install_packages_from_file scripts/packages/npm-globals.txt 'npm install -g'
        install_packages_from_file scripts/packages/cargo-crates.txt 'cargo install'
        install_packages_from_file scripts/packages/bun-globals.txt 'bun install -g'
        install_packages_from_file scripts/packages/pipx.txt 'pipx install'
    "
	log "--- Language Package Installation Complete ---"
}

# --- SYSTEM FIXES ---
run_system_fixes() {
	info "--- Running System Fixes ---"
	bash scripts/fixes.sh all
	log "--- System Fixes Complete ---"
}

# --- CLI INSTALLER ---
run_cli_installer() {
	info "--- Running CLI Tools Installer ---"
	source scripts/cli.sh && run_cli_installer_interactive
	ok "--- CLI Tools Installation Complete ---"
}

# --- PRE-INSTALL ---
run_preinstall() {
	info "--- Running Pre-Install Setup ---"
	run_privileged bash scripts/preinstall.sh
	log "--- Pre-Install Setup Complete ---"
}

# --- SNAP REMOVAL ---
run_snap_removal() {
	info "--- Running Snap Removal ---"
	source scripts/unsnap.sh && run_snap_removal_interactive
	ok "--- Snap Removal Complete ---"
}

# --- POST-INSTALL ---
run_post_install() {
	info "--- Running Post-Install ---"
	run_privileged bash scripts/post-install.sh
	ok "--- Post-Install Complete ---"
}

# --- SHELL ENVIRONMENT ---
setup_shell_environment() {
	setup_zinit_starship
}

# --- NVIDIA GPU SETUP ---
run_nvidia_setup() {
	info "--- Setting Up NVIDIA GPU ---"
	bash scripts/nvidia.sh
	log "--- NVIDIA GPU Setup Complete ---"
}

# --- SYSTEM CONFIGURATION ---
configure_system() {
	info "--- Configuring System (RAM + Power) ---"
	bash scripts/myconfig.sh
	log "--- System Configuration Complete ---"
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

	command -v starship >/dev/null && {
		warn "Setting up Starship prompt..."
		mkdir -p "$HOME/.config"
		log "Starship configuration ready."
	}

	warn "Rebuilding font cache..."
	fc-cache -fv
	log "--- Shell Environment Setup Complete ---"
}

# --- NERD FONTS ---
run_nerd_fonts_installer() {
	   info "--- Running Nerd Fonts Installer ---"
	   source scripts/nerd-fonts.sh && install_nerd_fonts
	   ok "--- Nerd Fonts Installation Complete ---"
}
