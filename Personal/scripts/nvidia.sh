#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================
# COLORS
# ===============================
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ===============================
# UTILITY FUNCTIONS
# ===============================
log() { echo -e "${GREEN}› $*${NC}"; }
warn() { echo -e "${YELLOW}› $*${NC}"; }
error() { echo -e "${RED}› $*${NC}"; }

command -v prime-select >/dev/null || { error "Install nvidia-prime first."; exit 1; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }

log "Switching NVIDIA GPU to on-demand..."
run_privileged prime-select on-demand
run_privileged systemctl mask gpu-manager.service
grep -q "LIBGL_DRI3_DISABLE" /etc/environment || echo "LIBGL_DRI3_DISABLE=true" | run_privileged tee -a /etc/environment >/dev/null

if ! command -v envycontrol &>/dev/null; then
    log "Installing envycontrol..."
    wget -O /tmp/envycontrol.deb "https://github.com/bayasdev/envycontrol/releases/download/v3.5.1/python3-envycontrol_3.5.1-1_all.deb"
    run_privileged dpkg -i /tmp/envycontrol.deb || run_privileged apt-get install -f -y
fi

log "Setting GPU to integrated mode..."
run_privileged envycontrol -s integrated
log "✅ GPU setup complete! Integrated graphics active."
