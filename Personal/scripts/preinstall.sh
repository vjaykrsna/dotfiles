#!/bin/bash
# Pre-Install System Preparation Script
# Update system and prepare for installation

set -euo pipefail
IFS=$'\n\t'

# --- COLORS ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}🔧 Pre-Install System Preparation${NC}"
echo -e "${YELLOW}⚠️  This script requires sudo access for system updates${NC}"

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Please run with sudo: sudo $0${NC}"
    exit 1
fi

# Update package lists
echo -e "${YELLOW}› Updating package lists...${NC}"
apt update

# Upgrade system packages
echo -e "${YELLOW}› Upgrading system packages...${NC}"
apt upgrade -y

# Install essential tools
echo -e "${YELLOW}› Installing essential build tools...${NC}"
apt install -y build-essential curl wget git software-properties-common

# Install Flatpak if not present
if ! command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}› Installing Flatpak...${NC}"
    apt install -y flatpak gnome-software-plugin-flatpak
fi

# Clean up
echo -e "${YELLOW}› Cleaning up...${NC}"
apt autoremove -y
apt autoclean

# Enable Flathub (basic setup)
echo -e "${YELLOW}› Adding Flathub remote...${NC}"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo -e "${GREEN}✅ Pre-install preparation complete!${NC}"
echo -e "${YELLOW}💡 You can now run './scripts/setup.sh' for the main installation${NC}"
