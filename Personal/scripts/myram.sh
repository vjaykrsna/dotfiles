#!/usr/bin/env bash
set -euo pipefail

# --- COLORS ---
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- UTILITY FUNCTIONS ---
log() { echo -e "${GREEN}› $*${NC}"; }
warn() { echo -e "${YELLOW}› $*${NC}"; }
run_privileged() { [ "$EUID" -eq 0 ] && "$@" || sudo "$@"; }

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

log "✅ Done! Active swap devices:"
swapon --show
zramctl
