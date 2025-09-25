#!/usr/bin/env bash
# Post-Install Configuration Script
# Final system tweaks and additional repositories

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them
trap 'error "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

info "🚀 Running Post-Install Configuration"

info "› Adding Flathub remote for Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

info "› Modernizing APT sources..."
run_privileged apt modernize-sources

info "› Installing Sekiro GRUB theme..."
rm -rf /tmp/sekiro_grub_theme
git clone --depth=1 https://github.com/semimqmo/sekiro_grub_theme /tmp/sekiro_grub_theme || error "Failed to clone Sekiro theme"
(cd /tmp/sekiro_grub_theme && run_privileged bash install.sh) || error "Failed to install Sekiro theme"
rm -rf /tmp/sekiro_grub_theme

info "› Installing Adwaita Colors theme..."
rm -rf /tmp/Adwaita-colors
git clone --depth=1 https://github.com/dpejoh/Adwaita-colors /tmp/Adwaita-colors || error "Failed to clone Adwaita theme"
(cd /tmp/Adwaita-colors && run_privileged bash ./setup -i) || error "Failed to install Adwaita theme"
rm -rf /tmp/Adwaita-colors

info "› Rebuilding font cache..."
fc-cache -fv 2>/dev/null || true

info "› Installing Micro editor plugins..."
micro -plugin install fzf || warn "Failed to install micro plugin fzf, skipping"
micro -plugin install wc || warn "Failed to install micro plugin wc, skipping"
micro -plugin install misspell || warn "Failed to install micro plugin misspell, skipping"
micro -plugin install autofmt || warn "Failed to install micro plugin autofmt, skipping"
micro -plugin install detectindent || warn "Failed to install micro plugin detectindent, skipping"
micro -plugin install editorconfig || warn "Failed to install micro plugin editorconfig, skipping"

ok "Post-install configuration complete!"
info "💡 You may want to run 'setup.sh' to check system health."
