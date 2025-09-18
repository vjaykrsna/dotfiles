#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "$(dirname "$0")/../installer.sh" # For logging and utility functions
fi

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
	error "Please run as root or with sudo"
fi

info "Running custom installations..."

# Setup system dependencies first
info "Installing base dependencies..."
apt update --quiet
apt install -y --no-install-recommends \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	software-properties-common \
	wget

# Create keyrings dir
install -m 0755 -d /etc/apt/keyrings

# --- Google Chrome ---
if ! command -v google-chrome &>/dev/null; then
	info "Setting up Google Chrome..."
	curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" |
		tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
	apt update && apt install -y google-chrome-stable
fi

# --- Docker ---
if ! command -v docker &>/dev/null; then
	info "Installing Docker..."
	apt install -y ca-certificates curl
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	chmod a+r /etc/apt/keyrings/docker.asc
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
		tee /etc/apt/sources.list.d/docker.list >/dev/null
	apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	# Add user to docker group if running with sudo
	if [ -n "${SUDO_USER:-}" ]; then
		info "Adding $SUDO_USER to docker group..."
		usermod -aG docker "$SUDO_USER"
	fi
fi

# --- VS Code ---
if ! command -v code &>/dev/null; then
	info "Setting up VS Code..."
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
	echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |
		tee /etc/apt/sources.list.d/vscode.list >/dev/null
	apt update && apt install -y code
fi

# Adjust ownership of /usr/share/code for theming
if [ -n "$SUDO_USER" ]; then
    info "Adjusting ownership of /usr/share/code..."
    chown -R "$SUDO_USER:$SUDO_USER" /usr/share/code 2>/dev/null || true
fi

# --- OnlyOffice ---
if ! dpkg -s onlyoffice-desktopeditors &>/dev/null; then
	info "Installing OnlyOffice Desktop Editors..."
	wget -qO /tmp/onlyoffice.deb https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
	DEBIAN_FRONTEND=noninteractive apt install -y /tmp/onlyoffice.deb
	rm -f /tmp/onlyoffice.deb
fi

# --- auto-cpufreq ---
if ! command -v auto-cpufreq &>/dev/null; then
	info "Installing auto-cpufreq..."
	git clone --depth=1 https://github.com/AdnanHodzic/auto-cpufreq.git /tmp/auto-cpufreq
	(cd /tmp/auto-cpufreq && ./auto-cpufreq-installer --install)

	# Enable auto-cpufreq as a daemon service
	info "Enabling auto-cpufreq daemon..."
	auto-cpufreq --install

	rm -rf /tmp/auto-cpufreq
fi

ok "Custom installations complete."
