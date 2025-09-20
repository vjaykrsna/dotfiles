#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Basic logging (fallback if installer.sh missing) ---
info()  { echo "[INFO] $*"; }
ok()    { echo "[ OK ] $*"; }
error() { echo "[ERR ] $*" >&2; }

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "../../core/installer.sh" # For logging and utility functions
fi

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    error "Please run as root or with sudo"
    exit 1
fi

info "Running custom installations..."

# Setup system dependencies first
info "Installing base dependencies..."
apt update -qq
apt install -y --no-install-recommends \
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
if ! command -v google-chrome &>/dev/null; then
    info "Setting up Google Chrome..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        -o /etc/apt/keyrings/google-chrome.gpg || {
        error "Failed to download Google key"; }
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    apt update -qq
    apt install -y google-chrome-stable || error "Failed to install Google Chrome"
fi

# --- Docker ---
if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    apt install -y ca-certificates curl || error "Failed to install ca-certificates/curl"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc || error "Failed to download Docker key"
    chmod a+r /etc/apt/keyrings/docker.asc
    CODENAME=$(lsb_release -cs)
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null || error "Failed to add Docker repo"
    apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || error "Failed to install Docker"

    if [[ -n "${SUDO_USER:-}" ]]; then
        info "Adding $SUDO_USER to docker group..."
        usermod -aG docker "$SUDO_USER"
    fi
fi

# --- VS Code ---
if ! command -v code &>/dev/null; then
    info "Setting up VS Code..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        -o /etc/apt/keyrings/packages.microsoft.gpg || {
        error "Failed to fetch Microsoft key"; }
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | tee /etc/apt/sources.list.d/vscode.list >/dev/null
    apt update -qq
    apt install -y code || error "Failed to install VS Code"
fi

# --- OnlyOffice ---
if ! dpkg -s onlyoffice-desktopeditors &>/dev/null; then
    info "Installing OnlyOffice Desktop Editors..."
    tmpdeb=/tmp/onlyoffice.deb
    wget -qO "$tmpdeb" https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb || {
        error "Failed to fetch OnlyOffice"; }
    DEBIAN_FRONTEND=noninteractive apt install -y "$tmpdeb" || error "Failed to install OnlyOffice"
    rm -f "$tmpdeb"
fi

# --- auto-cpufreq ---
if ! command -v auto-cpufreq &>/dev/null; then
    info "Installing auto-cpufreq..."
    git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git /tmp/auto-cpufreq || {
        error "Failed to clone auto-cpufreq repo"; }
    (cd /tmp/auto-cpufreq && ./auto-cpufreq-installer --install) || {
        error "auto-cpufreq installation failed"; }
    systemctl enable --now auto-cpufreq || true
    rm -rf /tmp/auto-cpufreq
fi

ok "Custom installations complete."
