#!/bin/bash
# NVIDIA GPU On-Demand Setup with envycontrol
set -euo pipefail

# Ensure prime-select exists
command -v prime-select >/dev/null || { echo "Install nvidia-prime first."; exit 1; }

log() { echo -e "\033[0;32m› $*\033[0m"; }
warn() { echo -e "\033[0;33m› $*\033[0m"; }

log "Switching NVIDIA GPU to on-demand mode..."
sudo prime-select on-demand

log "Disabling Ubuntu GPU manager..."
sudo systemctl mask gpu-manager.service

# Disable DRI3 safely
grep -q "LIBGL_DRI3_DISABLE" /etc/environment || echo "LIBGL_DRI3_DISABLE=true" | sudo tee -a /etc/environment > /dev/null

# Install envycontrol if not present
if ! command -v envycontrol &>/dev/null; then
    log "Downloading envycontrol..."
    ENVYCONTROL_DEB="/tmp/python3-envycontrol_3.5.1-1_all.deb"
    wget -O "$ENVYCONTROL_DEB" "https://github.com/bayasdev/envycontrol/releases/download/v3.5.1/python3-envycontrol_3.5.1-1_all.deb"

    log "Installing envycontrol..."
    sudo dpkg -i "$ENVYCONTROL_DEB" || sudo apt-get install -f -y
    rm "$ENVYCONTROL_DEB"
else
    log "envycontrol already installed."
fi

log "Setting GPU to integrated mode..."
sudo envycontrol -s integrated

log "✅ GPU setup complete! Integrated graphics active by default."
