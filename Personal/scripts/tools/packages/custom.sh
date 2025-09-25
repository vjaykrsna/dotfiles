#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utility functions
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/utils.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# Ensure we have the privileges we need; auto-elevate when possible
if [[ "$EUID" -ne 0 ]]; then
    warn "Custom package install requires elevation; re-running with sudo..."
    if command -v sudo >/dev/null 2>&1; then
        exec sudo -E -- "$0" "$@"
    fi
    fatal "Unable to obtain root privileges (sudo not available)."
fi

info "Running custom installations..."

# Setup system dependencies first
info "Installing base dependencies..."
# Use noninteractive apt-get for scripted installs
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    git

# Create keyrings dir if missing
install -m 0755 -d /etc/apt/keyrings

# --- Google Chrome ---
if ! command -v google-chrome &>/dev/null && ! command -v google-chrome-stable &>/dev/null; then
    info "Setting up Google Chrome..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg || fatal "Failed to download Google key"
    chmod a+r /etc/apt/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    apt-get update -q
    apt-get install -y google-chrome-stable || warn "Failed to install Google Chrome"
fi

# --- Docker ---
if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg || fatal "Failed to download Docker key"
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    CODENAME=$(lsb_release -cs)
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null || fatal "Failed to add Docker repo"
        
    apt-get update -q
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || warn "Failed to install Docker"

    if [[ -n "${SUDO_USER:-}" ]]; then
        info "Adding $SUDO_USER to docker group..."
        usermod -aG docker "$SUDO_USER"
        warn "User $SUDO_USER was added to group 'docker'. Please log out and log back in (or run 'newgrp docker') for this to take effect."
    fi
fi

# --- VS Code ---
if ! command -v code &>/dev/null; then
    info "Setting up VS Code..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg || fatal "Failed to fetch Microsoft key"
    chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | tee /etc/apt/sources.list.d/vscode.list >/dev/null
    apt-get update -q
    apt-get install -y code || warn "Failed to install VS Code"
fi

# --- OnlyOffice ---
if ! dpkg -s onlyoffice-desktopeditors &>/dev/null; then
    info "Installing OnlyOffice Desktop Editors..."
    wget -O /tmp/onlyoffice.deb https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors_amd64.deb || fatal "Failed to download OnlyOffice DEB"
    apt-get install -y fonts-dejavu fonts-crosextra-carlito || warn "Failed to install OnlyOffice dependencies"
    # Use apt to handle dependencies when installing local deb
    if ! apt-get install -y /tmp/onlyoffice.deb; then
        warn "apt installation of OnlyOffice failed, attempting dpkg and fix..."
        dpkg -i /tmp/onlyoffice.deb || warn "dpkg install failed for OnlyOffice"
        apt-get -f install -y || warn "Failed to fix unmet dependencies for OnlyOffice"
    fi
    rm -f /tmp/onlyoffice.deb
fi

# --- auto-cpufreq ---
if ! command -v auto-cpufreq &>/dev/null; then
    info "Installing auto-cpufreq..."
    tmpdir=$(mktemp -d)
    git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$tmpdir" || warn "Failed to clone auto-cpufreq repo, skipping"
    (cd "$tmpdir" && ./auto-cpufreq-installer --install) || warn "auto-cpufreq installation failed, skipping"
    systemctl daemon-reload
    systemctl enable --now auto-cpufreq || true
    rm -rf "$tmpdir"
fi

ok "Custom installations complete."
