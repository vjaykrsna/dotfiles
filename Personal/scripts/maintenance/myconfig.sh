#!/usr/bin/env bash
set -euo pipefail

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "../core/installer.sh" # For logging and utility functions
fi

# --- RAM CONFIGURATION ---
ZRAM_PERCENT=200   # % of RAM
RAM_GB=$(free -g | awk 'NR==2{print $2}')
DISK_SWAP_SIZE=$((RAM_GB * 3 / 2))G # 1.5x RAM
SWAP_FILE=/swap.img

info "💾 Configuring ZRAM to ${ZRAM_PERCENT}% of RAM..."
run_privileged sed -i "s/^PERCENT=.*/PERCENT=${ZRAM_PERCENT}/" /etc/default/zramswap || error "Failed to update zram config"
run_privileged systemctl restart zramswap.service || error "Failed to restart zramswap"

info "🗑️ Removing old disk swap if it exists..."
if swapon --show=NAME | grep -q "$SWAP_FILE"; then
    run_privileged swapoff "$SWAP_FILE" || warn "Failed to swapoff"
fi
[ -f "$SWAP_FILE" ] && run_privileged rm "$SWAP_FILE" || true

info "💽 Creating new ${DISK_SWAP_SIZE} swapfile..."
run_privileged fallocate -l $DISK_SWAP_SIZE "$SWAP_FILE" || error "Failed to allocate swapfile"
run_privileged chmod 600 "$SWAP_FILE"
run_privileged mkswap "$SWAP_FILE" || error "Failed to mkswap"
run_privileged swapon "$SWAP_FILE" || error "Failed to swapon"

# --- POWERTOP CONFIGURATION ---
SERVICE_NAME="powertop-autotune.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

if command -v powertop > /dev/null 2>&1; then
    info "⚡ Powertop found, configuring auto-tune service..."
    [ -f "$SERVICE_PATH" ] && warn "$SERVICE_NAME exists. Overwriting..."

    # --- CREATE SERVICE ---
    TMP_FILE="/tmp/$SERVICE_NAME"
    cat > "$TMP_FILE" << EOF
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

    run_privileged mv "$TMP_FILE" "$SERVICE_PATH" || error "Failed to create service file"

    ok "Service file created at $SERVICE_PATH"

    run_privileged systemctl daemon-reload
    run_privileged systemctl enable "$SERVICE_NAME" || error "Failed to enable $SERVICE_NAME"
    ok "$SERVICE_NAME enabled for auto-start"

    read -rp "Start powertop autotune now? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && run_privileged systemctl start "$SERVICE_NAME" && ok "Service started now" || error "Failed to start $SERVICE_NAME"

    ok "Done! Powertop will auto-tune 30s after every boot."
else
    warn "Powertop not found, skipping power optimization setup."
fi

# --- FINAL OUTPUT ---
ok "✅ Done! Active swap devices:"
swapon --show
zramctl
