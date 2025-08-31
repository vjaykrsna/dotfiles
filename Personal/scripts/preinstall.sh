#!/bin/bash
# Pre-Install System Preparation Script
# Update system and prepare for installation

set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies ---
# Note: This script is intended to be run standalone with sudo,
# but we source this to get logging functions.
source ./scripts/installer.sh

info "🔧 Pre-Install System Preparation"
warn "This script requires sudo access for system updates"

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
	error "Please run with sudo: sudo $0"
fi

# Update package lists
warn "› Updating package lists..."
apt update

# Upgrade system packages
warn "› Upgrading system packages..."
apt upgrade -y

# Install essential tools
warn "› Installing essential build tools..."
apt install -y build-essential curl wget git software-properties-common

# Install Flatpak if not present
if ! command -v flatpak &>/dev/null; then
	warn "› Installing Flatpak..."
	apt install -y flatpak gnome-software-plugin-flatpak
fi

# Clean up
warn "› Cleaning up..."
apt autoremove -y
apt autoclean

# Enable Flathub (basic setup)
warn "› Adding Flathub remote..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

ok "Pre-install preparation complete!"
info "💡 You can now run './scripts/setup.sh' for the main installation"
