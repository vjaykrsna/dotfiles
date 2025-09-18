#!/bin/bash
# Post-Install Configuration Script
# Final system tweaks and additional repositories

set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "$0")/installer.sh" # For logging and utility functions
fi

info "🚀 Running Post-Install Configuration"

info "› Adding Flathub remote for Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

info "› Modernizing APT sources..."
run_privileged apt modernize-sources

if command -v fc-cache &> /dev/null; then
    info "› Rebuilding font cache..."
    fc-cache -fv
fi

info "› Installing Sekiro GRUB theme..."
if [ ! -d "/tmp/sekiro_grub_theme" ]; then
    git clone --depth=1 https://github.com/semimqmo/sekiro_grub_theme /tmp/sekiro_grub_theme
fi
(cd /tmp/sekiro_grub_theme && run_privileged bash install.sh)
rm -rf /tmp/sekiro_grub_theme

info "› Installing Adwaita Colors theme..."
if [ ! -d "/tmp/Adwaita-colors" ]; then
    git clone --depth=1 https://github.com/dpejoh/Adwaita-colors /tmp/Adwaita-colors
fi
(cd /tmp/Adwaita-colors && run_privileged bash ./setup -i)
rm -rf /tmp/Adwaita-colors

info "› Installing Micro editor plugins..."
micro -plugin install fzf
micro -plugin install wc
micro -plugin install misspell
micro -plugin install autofmt
micro -plugin install detectindent
micro -plugin install editorconfig

ok "Post-install configuration complete!"
info "💡 You may want to run 'setup.sh' to check system health."
