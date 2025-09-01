#!/bin/bash
# Nerd Font Installation Script

set -euo pipefail
IFS=$'\n\t'

# This function is intended to be sourced by other scripts that have already
# sourced 'installer.sh' to provide the logging functions (info, ok, warn, etc.)

install_nerd_fonts() {
    info "--- Installing Nerd Fonts ---"
    local FONT_DIR="/usr/local/share/fonts/nerd-fonts"
    local TMP_DIR="/tmp"

    # JetBrains Mono Nerd Font
    if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
        info "› Downloading JetBrains Mono Nerd Font..."
        cd "$TMP_DIR"
        curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
        
        info "› Installing JetBrains Mono Nerd Font..."
        sudo mkdir -p "$FONT_DIR/JetBrainsMono"
        sudo tar -xJf JetBrainsMono.tar.xz -C "$FONT_DIR/JetBrainsMono/"
        rm JetBrainsMono.tar.xz
        ok "  JetBrains Mono Nerd Font installed."
    else
        warn "› JetBrains Mono Nerd Font already installed. Skipping."
    fi

    # Fira Code Nerd Font
    if [ ! -d "$FONT_DIR/FiraCode" ]; then
        info "› Downloading Fira Code Nerd Font..."
        cd "$TMP_DIR"
        curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz

        info "› Installing Fira Code Nerd Font..."
        sudo mkdir -p "$FONT_DIR/FiraCode"
        sudo tar -xJf FiraCode.tar.xz -C "$FONT_DIR/FiraCode/"
        rm FiraCode.tar.xz
        ok "  Fira Code Nerd Font installed."
    else
        warn "› Fira Code Nerd Font already installed. Skipping."
    fi

    info "› Rebuilding font cache..."
    sudo fc-cache -fv
    
    ok "--- Nerd Fonts Installation Complete ---"
}
