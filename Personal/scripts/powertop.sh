#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================
# COLORS & UTILS
# ===============================
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}› $*${NC}"; }
warn() { echo -e "${YELLOW}› $*${NC}"; }
error() { echo -e "${RED}› $*${NC}"; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }

# ===============================
# CONFIG
# ===============================
SERVICE_NAME="powertop-autotune.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# ===============================
# PRECHECKS
# ===============================
command -v powertop >/dev/null 2>&1 || { error "powertop not found. Install it first."; exit 1; }
[ -f "$SERVICE_PATH" ] && warn "$SERVICE_NAME exists. Overwriting..."

# ===============================
# CREATE SERVICE
# ===============================
TMP_FILE="/tmp/$SERVICE_NAME"
cat > "$TMP_FILE" <<EOF
[Unit]
Description=Powertop Auto Tune
After=multi-user.target
Wants=multi-user.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 30
ExecStart=/usr/sbin/powertop --auto-tune
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

run_privileged mv "$TMP_FILE" "$SERVICE_PATH"
log "Service file created at $SERVICE_PATH"

# ===============================
# ENABLE & RELOAD
# ===============================
run_privileged systemctl daemon-reload
run_privileged systemctl enable "$SERVICE_NAME"
log "$SERVICE_NAME enabled for auto-start"

# ===============================
# OPTIONAL IMMEDIATE START
# ===============================
read -rp "Start powertop autotune now? [y/N]: " ans
[[ "$ans" =~ ^[Yy]$ ]] && run_privileged systemctl start "$SERVICE_NAME" && log "Service started now"

log "Done! Powertop will auto-tune 30s after every boot."
