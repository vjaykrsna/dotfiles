#!/usr/bin/env bash
# Language Runtime Installation Module
# Contains language runtime setup functions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/bootstrap.sh"
ensure_runtime_tmpdir
source "$SCRIPT_DIR/package_installer.sh"  # For install_packages_from_file

setup_nvm() {
    warn "Setting up NVM..."
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        info "NVM already installed."
    else
        local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${CONFIG[NVM_VERSION]}/install.sh"
        download_and_exec "$nvm_url" "nvm" "bash \"\$1\""
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
        local rust_url="https://sh.rustup.rs"
        download_and_exec "$rust_url" "rust" "sh \"\$1\" -s -- -y"
        load_language_env
    }
}

setup_bun() {
    command -v bun > /dev/null || {
        warn "Installing Bun..."
        local bun_url="https://bun.sh/install"
        download_and_exec "$bun_url" "bun" "bash \"\$1\""
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
