#!/usr/bin/env bash
# Pre-Install System Preparation Script
# Update system and prepare for installation

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/logging.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

info "🔧 Pre-Install System Preparation"
info "This script requires sudo access for system updates"

# Check if running with sudo
if [[ "$EUID" -ne 0 ]]; then
    fatal "Please run with sudo: sudo $0"
fi

# Update package lists
info "› Updating package lists..."
apt-get update

# Upgrade system packages
info "› Upgrading system packages..."
apt upgrade -y

# Install essential tools
info "› Installing essential build tools..."
apt install -y build-essential curl wget git software-properties-common

# Install Flatpak if not present
if ! command -v flatpak &> /dev/null; then
    info "› Installing Flatpak..."
    apt install -y flatpak gnome-software-plugin-flatpak
fi

# Clean up
info "› Cleaning up..."
apt autoremove -y
apt autoclean

# Enable Flathub (basic setup)
info "› Adding Flathub remote..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ok "Pre-install preparation complete!"
info "💡 You can now run './scripts/setup.sh' for the main installation"
