#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "../core/installer.sh" # For logging and utility functions
fi

# Revert flag
if [[ "$1" == "revert" ]]; then
    info "Reverting to full NVIDIA..."
    run_privileged envycontrol --reset || error "Envycontrol reset failed"
    run_privileged prime-select nvidia || error "Prime-select nvidia failed"
    ok "NVIDIA reverted to full mode."
    exit 0
fi

command -v prime-select > /dev/null || {
    error "Install nvidia-prime first."
    exit 1
}

info "Switching NVIDIA GPU to on-demand..."
run_privileged prime-select on-demand
run_privileged systemctl mask gpu-manager.service
grep -q "LIBGL_DRI3_DISABLE" /etc/environment || echo "LIBGL_DRI3_DISABLE=true" | run_privileged tee -a /etc/environment > /dev/null

if ! command -v envycontrol &> /dev/null; then
    info "Installing envycontrol..."
    wget -O /tmp/envycontrol.deb "https://github.com/bayasdev/envycontrol/releases/download/v3.5.1/python3-envycontrol_3.5.1-1_all.deb"
    run_privileged dpkg -i /tmp/envycontrol.deb || run_privileged apt-get install -f -y
fi

info "Setting GPU to integrated mode..."
run_privileged envycontrol -s integrated
ok "GPU setup complete! Integrated graphics active."
