#!/bin/bash
# Post-Install Configuration Script
# Final system tweaks and additional repositories

set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies ---
source ./scripts/installer.sh # For logging and utility functions

info "🚀 Running Post-Install Configuration"

warn "› Adding Flathub remote for Flatpak..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

warn "› Modernizing APT sources..."
run_privileged apt modernize-sources

if command -v fc-cache &>/dev/null; then
	warn "› Rebuilding font cache..."
	fc-cache -fv
fi

warn "› Installing Sekiro GRUB theme..."
if [ ! -d "/tmp/sekiro_grub_theme" ]; then
	git clone https://github.com/semimqmo/sekiro_grub_theme /tmp/sekiro_grub_theme
fi
(cd /tmp/sekiro_grub_theme && sudo bash install.sh)
rm -rf /tmp/sekiro_grub_theme

ok "Post-install configuration complete!"
info "💡 You may want to run 'setup.sh' to check system health."
