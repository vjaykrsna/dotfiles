#!/usr/bin/env bash
set -euo pipefail

# ===============================
# COLORS & UTILS
# ===============================
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
log() { echo -e "${GREEN}› $*${NC}"; }
warn() { echo -e "${YELLOW}› $*${NC}"; }
error() { echo -e "${RED}› $*${NC}"; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }

# ===============================
# RAM CONFIGURATION
# ===============================
# --- CONFIG ---
ZRAM_PERCENT=200       # % of RAM
DISK_SWAP_SIZE=12G     # disk swap size
SWAP_FILE=/swap.img

log "💾 Configuring ZRAM to ${ZRAM_PERCENT}% of RAM..."
run_privileged sed -i "s/^PERCENT=.*/PERCENT=${ZRAM_PERCENT}/" /etc/default/zramswap
run_privileged systemctl restart zramswap.service

log "🗑️ Removing old disk swap if it exists..."
if swapon --show=NAME | grep -q "$SWAP_FILE"; then
    run_privileged swapoff "$SWAP_FILE"
fi
[ -f "$SWAP_FILE" ] && run_privileged rm "$SWAP_FILE"

log "💽 Creating new ${DISK_SWAP_SIZE} swapfile..."
run_privileged fallocate -l $DISK_SWAP_SIZE "$SWAP_FILE"
run_privileged chmod 600 "$SWAP_FILE"
run_privileged mkswap "$SWAP_FILE"
run_privileged swapon "$SWAP_FILE"

# ===============================
# POWERTOP CONFIGURATION
# ===============================
# --- CONFIG ---
SERVICE_NAME="powertop-autotune.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# --- PRECHECKS ---
if command -v powertop >/dev/null 2>&1; then
    log "⚡ Powertop found, configuring auto-tune service..."
    [ -f "$SERVICE_PATH" ] && warn "$SERVICE_NAME exists. Overwriting..."
    
    # --- CREATE SERVICE ---
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
    
    # --- ENABLE & RELOAD ---
    run_privileged systemctl daemon-reload
    run_privileged systemctl enable "$SERVICE_NAME"
    log "$SERVICE_NAME enabled for auto-start"
    
    # --- OPTIONAL IMMEDIATE START ---
    read -rp "Start powertop autotune now? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && run_privileged systemctl start "$SERVICE_NAME" && log "Service started now"
    
    log "Done! Powertop will auto-tune 30s after every boot."
else
    warn "Powertop not found, skipping power optimization setup."
fi

# ===============================
# FINAL OUTPUT
# ===============================
log "✅ Done! Active swap devices:"
swapon --show
zramctl
