#!/usr/bin/env bash
set -euo pipefail

# --- Sourcing Dependencies (only when running standalone) ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    source "$SCRIPT_DIR/../core/installer.sh" # For logging and utility functions
fi

# --- RAM CONFIGURATION ---
ZRAM_PERCENT=200   # % of RAM
RAM_MB=$(free -m | awk 'NR==2{print $2}')
DISK_SWAP_SIZE=$((RAM_MB * 3 / 2))M # 1.5x RAM
SWAP_FILE=/swap.img

info "💾 Configuring ZRAM to ${ZRAM_PERCENT}% of RAM..."
run_privileged sed -i "s/^PERCENT=.*/PERCENT=${ZRAM_PERCENT}/" /etc/default/zramswap || error "Failed to update zram config"
run_privileged systemctl restart zramswap.service || error "Failed to restart zramswap"

info "🗑️ Removing old disk swap if it exists..."
run_privileged swapoff "$SWAP_FILE" 2>/dev/null || true
run_privileged rm -f "$SWAP_FILE"

info "💽 Creating new ${DISK_SWAP_SIZE} swapfile..."
if ! run_privileged fallocate -l "$DISK_SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
    run_privileged dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((RAM_MB * 3 / 2)) status=progress || error "Failed to create swapfile"
fi
run_privileged chmod 600 "$SWAP_FILE"
run_privileged mkswap "$SWAP_FILE" || error "Failed to mkswap"
run_privileged swapon "$SWAP_FILE" || error "Failed to swapon"

# --- POWERTOP CONFIGURATION ---
if command -v powertop > /dev/null 2>&1; then
    SERVICE_NAME="powertop-autotune.service"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

    info "⚡ Powertop found, configuring auto-tune service..."
    [ -f "$SERVICE_PATH" ] && warn "$SERVICE_NAME exists. Overwriting..."

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

    run_privileged mv "$TMP_FILE" "$SERVICE_PATH" || error "Powertop Service file creation failed"
    ok "Service file created at $SERVICE_PATH"

    run_privileged systemctl daemon-reload
    run_privileged systemctl enable "$SERVICE_NAME" || error "Enable failed"
    run_privileged systemctl start "$SERVICE_NAME" || warn "Start failed (may need reboot)"
    ok "Done! Powertop will auto-tune 30s after every boot."
else
    warn "Powertop not found, skipping power optimization setup."
fi

# --- FINAL OUTPUT ---
ok "✅ Done! Active swap devices:"
swapon --show || true
command -v zramctl >/dev/null && zramctl || true
