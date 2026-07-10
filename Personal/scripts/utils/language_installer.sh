#!/usr/bin/env bash
# Language Runtime Installation Module
# Contains language runtime setup functions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/bootstrap.sh"
ensure_runtime_tmpdir
source "$SCRIPT_DIR/package_installer.sh"  # For install_packages_from_file

setup_nvm() {
    warn "Setting up NVM..."
    if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
        local nvm_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${CONFIG[NVM_VERSION]}/install.sh"
        download_and_exec "$nvm_url" "nvm" "bash \"\$1\""
    else
        info "NVM already installed."
    fi

    export NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh" 2> /dev/null || true
    source "$NVM_DIR/bash_completion" 2> /dev/null || true

    command -v nvm > /dev/null || fatal "Failed to load nvm."

    local current
    current="$(nvm current)"

    if [[ "$current" == "none" ]]; then
        nvm install --lts
    else
        nvm install --lts --reinstall-packages-from=current
    fi

    nvm alias default 'lts/*'
    nvm use --lts

    corepack enable
}

setup_rust() {
    if command -v rustup >/dev/null; then
        info "Updating Rust..."
        rustup update
    else
        warn "Installing Rust..."
        local rust_url="https://sh.rustup.rs"
        download_and_exec "$rust_url" "rust" "sh \"\$1\" -s -- -y"
        load_language_env
    fi
}

setup_bun() {
    if command -v bun >/dev/null; then
        info "Updating Bun..."
        bun upgrade
    else
        warn "Installing Bun..."
        local bun_url="https://bun.sh/install"
        download_and_exec "$bun_url" "bun" "bash \"\$1\""
        load_language_env
    fi
}

setup_pipx() {
    command -v pipx > /dev/null || {
        warn "Installing pipx via apt..."
        run_privileged apt-get install -y pipx
    }
    warn "Ensuring pipx path..."
    python3 -m pipx ensurepath
    pipx upgrade-all
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

    corepack enable

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
