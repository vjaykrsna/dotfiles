#!/bin/bash
# Nerd Font Installation Script

set -euo pipefail
IFS=$'\n\t'


# Logging functions (simple version)
info() { echo "[INFO] $1"; }
ok() { echo "[OK] $1"; }
warn() { echo "[WARN] $1"; }

install_nerd_fonts() {
    info "--- Installing Nerd Fonts ---"
    local FONT_DIR="$HOME/.local/share/fonts"
    local TMP_DIR="/tmp"

    mkdir -p "$FONT_DIR"

    # JetBrains Mono Nerd Font
    info "› Downloading JetBrains Mono Nerd Font..."
    cd "$TMP_DIR"
    curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
    
    info "› Installing JetBrains Mono Nerd Font..."
    tar -xJf JetBrainsMono.tar.xz -C "$FONT_DIR/"
    rm JetBrainsMono.tar.xz
    ok "  JetBrains Mono Nerd Font installed."

    # Fira Code Nerd Font
    info "› Downloading Fira Code Nerd Font..."
    cd "$TMP_DIR"
    curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz

    info "› Installing Fira Code Nerd Font..."
    tar -xJf FiraCode.tar.xz -C "$FONT_DIR/"
    rm FiraCode.tar.xz
    ok "  Fira Code Nerd Font installed."

    # Geist Mono Nerd Font
    info "› Downloading Geist Mono Nerd Font..."
    cd "$TMP_DIR"
    curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/GeistMono.tar.xz

    info "› Installing Geist Mono Nerd Font..."
    tar -xJf GeistMono.tar.xz -C "$FONT_DIR/"
    rm GeistMono.tar.xz
    ok "  Geist Mono Nerd Font installed."

    info "› Rebuilding font cache..."
    fc-cache -fv
    
    ok "--- Nerd Fonts Installation Complete ---"
}

install_nerd_fonts
