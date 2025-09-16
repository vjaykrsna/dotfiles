#!/bin/bash
# Nerd Font Installation Script with Storage Optimization (FINAL)

set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "$0")/installer.sh" # For logging and utility functions
fi

# Function to clean up unused fonts and reduce storage usage
cleanup_unused_fonts() {
    local FONT_DIR="$HOME/.local/share/fonts"

    info "Current font directory size:"
    du -sh "$FONT_DIR"

    info "Whitelisting essential font weights (Regular, Italic, Medium, Bold + Italics)..."

    find "$FONT_DIR" -type f -name "*NerdFont*" \
        -not -regex ".*NerdFont-\(Regular\|Italic\|RegularItalic\|Medium\|MediumItalic\|Bold\|BoldItalic\)\.\(ttf\|otf\)" \
        -delete 2> /dev/null || true

    info "Font cleanup completed."
    info "New font directory size:"
    du -sh "$FONT_DIR"

    info "Fonts kept:"
    ls -1 "$FONT_DIR" | grep "NerdFont" | sort || true
}

# Selective font installation (JetBrains Mono only)
install_selective_fonts() {
    info "--- Installing Selective Nerd Fonts (Storage Optimized) ---"
    local FONT_DIR="$HOME/.local/share/fonts"
    local TMP_DIR="/tmp"
    mkdir -p "$FONT_DIR"

    if [[ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]] || [[ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.otf" ]]; then
        info "› JetBrains Mono already installed, skipping download."
    else
        info "› Downloading JetBrains Mono Nerd Font..."
        cd "$TMP_DIR"
        if curl -sOL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz; then
            info "› Installing JetBrains Mono Nerd Font..."
            tar -xJf JetBrainsMono.tar.xz -C "$FONT_DIR/"
            rm JetBrainsMono.tar.xz
            ok "JetBrains Mono Nerd Font installed."
        else
            error "Failed to download JetBrains Mono Nerd Font"
        fi
    fi

    cleanup_unused_fonts

    info "› Rebuilding font cache..."
    fc-cache -v "$FONT_DIR"

    ok "--- Selective Nerd Fonts Installation Complete ---"
}

# Full font installation (JetBrains, FiraCode, GeistMono)
install_all_fonts() {
    info "--- Installing All Nerd Fonts ---"
    local FONT_DIR="$HOME/.local/share/fonts"
    local TMP_DIR="/tmp"
    mkdir -p "$FONT_DIR"

    declare -A FONTS=(
        ["JetBrainsMono"]="JetBrainsMono"
        ["FiraCode"]="FiraCode"
        ["GeistMono"]="GeistMono"
    )

    for FONT in "${!FONTS[@]}"; do
        if [[ -f "$FONT_DIR/${FONT}NerdFont-Regular.ttf" ]] || [[ -f "$FONT_DIR/${FONT}NerdFont-Regular.otf" ]]; then
            info "› $FONT already installed, skipping download."
        else
            info "› Downloading $FONT Nerd Font..."
            cd "$TMP_DIR"
            if curl -sOL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONTS[$FONT]}.tar.xz"; then
                info "› Installing $FONT Nerd Font..."
                tar -xJf "${FONTS[$FONT]}.tar.xz" -C "$FONT_DIR/"
                rm "${FONTS[$FONT]}.tar.xz"
                ok "$FONT Nerd Font installed."
            else
                warn "Failed to download $FONT Nerd Font"
            fi
        fi
    done

    cleanup_unused_fonts

    info "› Rebuilding font cache..."
    fc-cache -v "$FONT_DIR"

    ok "--- All Nerd Fonts Installation Complete ---"
}

# Main function
install_nerd_fonts() {
    if [[ "${1:-}" == "all" ]]; then
        install_all_fonts
    else
        install_selective_fonts
    fi
}

# Allow running standalone or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nerd_fonts "$@"
fi
