#!/usr/bin/env bash
# nvidia.sh - Configure NVIDIA GPU for power saving (integrated mode) or revert to full mode
# Usage: sudo ./nvidia.sh [revert]
# Example: sudo ./nvidia.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utility functions
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"

# Trap errors to log them and exit via fatal()
set_robust_error_handling

setup_integrated_mode() {
    info "Masking GPU manager service..."
    run_privileged systemctl mask gpu-manager.service

    info "Disabling DRI3 for OpenGL compatibility..."
    if ! grep -q "LIBGL_DRI3_DISABLE" /etc/environment; then
        echo "LIBGL_DRI3_DISABLE=true" | run_privileged tee -a /etc/environment > /dev/null
    fi

    if ! command -v envycontrol &> /dev/null; then
        info "Installing envycontrol..."
        wget -O /tmp/envycontrol.deb "https://github.com/bayasdev/envycontrol/releases/download/v3.5.1/python3-envycontrol_3.5.1-1_all.deb" || fatal "Failed to download envycontrol"
        run_privileged dpkg -i /tmp/envycontrol.deb || run_privileged apt-get install -f -y || fatal "Failed to install envycontrol"
    fi

    info "Setting GPU to integrated mode..."
    run_privileged envycontrol -s integrated
    ok "GPU setup complete! Integrated graphics active."
}

revert_to_nvidia() {
    info "Reverting to full NVIDIA..."
    run_privileged envycontrol --reset || fatal "Envycontrol reset failed"
    run_privileged systemctl unmask gpu-manager.service || true
    run_privileged sed -i '/LIBGL_DRI3_DISABLE/d' /etc/environment || true
    ok "NVIDIA reverted to full mode."
}

# Main logic
if [[ "${1-}" == "revert" ]]; then
    revert_to_nvidia
else
    setup_integrated_mode
fi
