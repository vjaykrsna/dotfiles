#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging/utilities
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/utils.sh"

# Trap errors to log them and exit via fatal()
trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# Root check
if [[ "$EUID" -ne 0 ]]; then
    warn "Custom package install requires elevation; re-running with sudo..."
    if command -v sudo >/dev/null 2>&1; then
        exec sudo -E -- "$0" "$@"
    fi
    fatal "Unable to obtain root privileges (sudo not available)."
fi

info "Installing custom packages..."

# Base deps
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release software-properties-common wget git

install -m 0755 -d /etc/apt/keyrings

# --- Google Chrome ---
if ! command -v google-chrome &>/dev/null && ! command -v google-chrome-stable &>/dev/null; then
    info "Installing Google Chrome..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        | tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    apt-get install -y google-chrome-stable || warn "Chrome install failed"
fi

# --- Docker ---
if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    CODENAME=$(lsb_release -cs)
    if ! curl -fsI "https://download.docker.com/linux/ubuntu/dists/${CODENAME}/Release" >/dev/null; then
        warn "Docker repo does not yet provide packages for '$CODENAME'; falling back to 'noble'."
        CODENAME="noble"
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || warn "Docker install failed"

    if [[ -n "${SUDO_USER:-}" ]]; then
        info "Adding $SUDO_USER to docker group..."
        usermod -aG docker "$SUDO_USER"
        warn "User $SUDO_USER added to 'docker'. Relog required."
    fi
fi

# --- VS Code ---
if ! command -v code &>/dev/null; then
    info "Installing VS Code..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | tee /etc/apt/sources.list.d/vscode.list >/dev/null
    apt-get install -y code || warn "VS Code install failed"
fi

# --- OnlyOffice ---
if ! dpkg -s onlyoffice-desktopeditors &>/dev/null; then
    info "Installing OnlyOffice..."
    apt-get install -y fonts-dejavu fonts-crosextra-carlito || warn "Failed to install OnlyOffice dependencies"
    wget -O /tmp/onlyoffice.deb https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors_amd64.deb
    apt-get install -y /tmp/onlyoffice.deb || warn "OnlyOffice install failed"
    rm -f /tmp/onlyoffice.deb
fi

# --- auto-cpufreq ---
if ! command -v auto-cpufreq &>/dev/null; then
    info "Installing auto-cpufreq..."
    tmpdir=$(mktemp -d)
    if git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git "$tmpdir"; then
        (cd "$tmpdir" && ./auto-cpufreq-installer --install) || warn "auto-cpufreq install error"
    else
        warn "Clone failed, skipping auto-cpufreq"
    fi
    rm -rf "$tmpdir"
fi

ok "All custom installs complete."
