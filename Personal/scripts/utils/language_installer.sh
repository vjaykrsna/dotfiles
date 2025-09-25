#!/usr/bin/env bash
# Language Runtime Installation Module
# Contains language runtime setup functions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source dependencies
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/utils.sh"
ensure_runtime_tmpdir
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/package_installer.sh"  # For install_packages_from_file

setup_nvm() {
    warn "Setting up NVM..."
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        info "NVM already installed."
    else
        local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${CONFIG[NVM_VERSION]}/install.sh"
        local nvm_inst
        nvm_inst=$(mktemp "$SETUP_TMPDIR/install-nvm.XXXXXX") || fatal "Failed to create temp file for NVM installer"
        if curl -fsSL "$nvm_url" -o "$nvm_inst"; then
            if bash "$nvm_inst"; then
                info "NVM installed"
            else
                warn "NVM install script failed"
            fi
            rm -f "$nvm_inst"
        else
            warn "Failed to download NVM installer"
        fi
    fi

    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh" 2> /dev/null || true
    source "$NVM_DIR/bash_completion" 2> /dev/null || true

    command -v node > /dev/null || {
        warn "Installing Node.js..."
        nvm install node
        nvm use node
    }
}

setup_rust() {
    command -v cargo > /dev/null || {
        warn "Installing Rust..."
        local rust_inst
        rust_inst=$(mktemp "$SETUP_TMPDIR/install-rust.XXXXXX") || fatal "Failed to create temp file for Rust installer"
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rust_inst"; then
            if sh "$rust_inst" -s -- -y; then
                info "Rust installed"
            else
                warn "Rust install script failed"
            fi
            rm -f "$rust_inst"
        else
            warn "Failed to download Rust installer"
        fi
        load_language_env
    }
}

setup_bun() {
    command -v bun > /dev/null || {
        warn "Installing Bun..."
        local bun_inst
        bun_inst=$(mktemp "$SETUP_TMPDIR/install-bun.XXXXXX") || fatal "Failed to create temp file for Bun installer"
        if curl -fsSL https://bun.sh/install -o "$bun_inst"; then
            if bash "$bun_inst"; then
                info "Bun installed"
            else
                warn "Bun install script failed"
            fi
            rm -f "$bun_inst"
        else
            warn "Failed to download Bun installer"
        fi
        load_language_env
    }
}

setup_pipx() {
    command -v pipx > /dev/null || {
        warn "Installing pipx via apt..."
        run_privileged apt-get install -y pipx
    }
    warn "Ensuring pipx path..."
    python3 -m pipx ensurepath
}

setup_language_environment() {
    info "--- Setting Up Language Environment ---"
    setup_nvm
    setup_rust
    setup_bun
    setup_pipx
    info "--- Language Environment Setup Complete ---"
}

install_language_packages_internal() {
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
    load_language_env

    cd "$SCRIPT_DIR" || return

    info "Installing npm global packages..."
    install_packages_from_file "$SCRIPT_DIR/../tools/packages/npm-globals.txt" npm install -g
    install_packages_from_file "$SCRIPT_DIR/../tools/packages/cargo-crates.txt" cargo install
    install_packages_from_file "$SCRIPT_DIR/../tools/packages/bun-globals.txt" bun install -g
    install_packages_from_file "$SCRIPT_DIR/../tools/packages/pipx.txt" pipx install
}

install_language_packages() {
    info "--- Installing Language Packages ---"
    run_as_user install_language_packages_internal
    info "--- Language Package Installation Complete ---"
}
