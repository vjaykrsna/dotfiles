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

if command -v fc-cache &> /dev/null; then
    warn "› Rebuilding font cache..."
    fc-cache -fv
fi

ok "Post-install configuration complete!"
info "💡 You may want to run 'setup.sh' to check system health."
