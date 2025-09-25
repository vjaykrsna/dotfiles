#!/usr/bin/env bash
# nerd-fonts.sh - Install/cleanup Nerd Fonts
# Usage: source nerd-fonts.sh && install_nerd_fonts
# Example: ./nerd-fonts.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# --- Pre-check commands ---
for cmd in curl tar fc-cache; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "Required command '$cmd' is missing. Install it and retry."
    fi
done

# Cleanup unused Nerd Fonts
cleanup_unused_fonts() {
    local FONT_DIR="$HOME/.local/share/fonts"

    info "Current font directory size:"
    du -sh "$FONT_DIR" || true

    info "Whitelisting essential font weights (Regular, Italic, Medium, Bold + Italics)..."

    find "$FONT_DIR" -type f -name "*NerdFont*" \
        ! -regex ".*NerdFont-\(Regular\|Italic\|RegularItalic\|Medium\|MediumItalic\|Bold\|BoldItalic\)\.\(ttf\|otf\)" \
        -delete 2>/dev/null || true

    info "Font cleanup completed."
    info "New font directory size:"
    du -sh "$FONT_DIR" || true

    info "Fonts kept:"
    for f in "$FONT_DIR"/*NerdFont*; do [ -e "$f" ] || continue; echo "$f"; done | sort || true
}

# Rebuild font cache
rebuild_font_cache() {
    local FONT_DIR="$1"
    info "› Rebuilding font cache..."
    fc-cache -v "$FONT_DIR" || warn "fc-cache failed"
}

# Generic font installer
install_font() {
    local FONT_NAME="$1"
    local FONT_DIR="$HOME/.local/share/fonts"
    local TMP_DIR
    TMP_DIR=$(mktemp -d)

    mkdir -p "$FONT_DIR"

    if compgen -G "$FONT_DIR/${FONT_NAME}NerdFont-Regular.*" >/dev/null; then
        info "› $FONT_NAME already installed, skipping."
        return
    fi

    info "› Downloading $FONT_NAME Nerd Font..."
    if curl -sL -o "$TMP_DIR/${FONT_NAME}.tar.xz" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.tar.xz"; then
        info "› Installing $FONT_NAME Nerd Font..."
        tar -xJf "$TMP_DIR/${FONT_NAME}.tar.xz" -C "$FONT_DIR/" || warn "Failed to extract $FONT_NAME, skipping"
        ok "$FONT_NAME Nerd Font installed."
    else
        warn "Failed to download $FONT_NAME Nerd Font, skipping"
    fi

    rm -rf "$TMP_DIR"
}

# Full font installation
install_all_fonts() {
    info "--- Installing All Nerd Fonts ---"
    local FONTS=( "JetBrainsMono" "FiraCode" "Hack" )
    for f in "${FONTS[@]}"; do
        install_font "$f"
    done
    cleanup_unused_fonts
    rebuild_font_cache "$HOME/.local/share/fonts"
    ok "--- All Nerd Fonts Installation Complete ---"
}

# Main entry
install_nerd_fonts() {
    install_all_fonts
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nerd_fonts "$@"
fi
