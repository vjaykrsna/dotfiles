#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging/utilities
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/utils.sh"

# Trap errors to log them and exit via fatal()
set_robust_error_handling

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
