#!/bin/bash
# Post-Install Configuration Script
# Final system tweaks and additional repositories

set -euo pipefail
IFS=$'\n\t'

# --- COLORS ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

echo -e "${GREEN}🚀 Running Post-Install Configuration${NC}"

# Add Flathub remote
echo -e "${YELLOW}› Adding Flathub remote for Flatpak...${NC}"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Modernize APT sources
echo -e "${YELLOW}› Modernizing APT sources...${NC}"
sudo apt modernize-sources

# Rebuild font cache
if command -v fc-cache &> /dev/null; then
    echo -e "${YELLOW}› Rebuilding font cache...${NC}"
    fc-cache -fv
fi

echo -e "${GREEN}✅ Post-install configuration complete!${NC}"
echo -e "${YELLOW}💡 You may want to run 'setup.sh' option 15 to check system health.${NC}"
