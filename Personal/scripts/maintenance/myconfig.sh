#!/usr/bin/env bash
# myconfig.sh - Configure ZRAM, swapfile and optional powertop service
# Usage: sudo ./myconfig.sh
# Example: sudo ./myconfig.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source logging and utility functions
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/utils.sh"
source "$SCRIPT_DIR/../utils/config.sh"

# Trap errors to log them
trap 'error "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR

# Provide safe defaults if CONFIG is not set
: "${CONFIG[ZRAM_PERCENT]:=200}"
: "${CONFIG[SWAP_MULTIPLIER]:=1.5}"

# --- RAM CONFIGURATION ---
ZRAM_PERCENT=${CONFIG[ZRAM_PERCENT]}   # % of RAM
RAM_MB=$(free -m | awk 'NR==2{print $2}')
SWAP_MULTIPLIER_RAW=${CONFIG[SWAP_MULTIPLIER]}
DISK_SWAP_SIZE_MB=$(awk -v r="$RAM_MB" -v m="$SWAP_MULTIPLIER_RAW" 'BEGIN{printf "%d", (r * m / 2 + 0.5)}')
DISK_SWAP_SIZE="${DISK_SWAP_SIZE_MB}M"
SWAP_FILE=/swap.img

# Define create_swap_file before usage
create_swap_file() {
    info "Creating swapfile of size ${DISK_SWAP_SIZE}..."
    if ! run_privileged fallocate -l "$DISK_SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
        # Fallback to dd with integer count in MB
        run_privileged dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$DISK_SWAP_SIZE_MB" status=progress || error "Failed to create swapfile"
    fi
    run_privileged chmod 600 "$SWAP_FILE"
    run_privileged mkswap "$SWAP_FILE" || error "Failed to mkswap"
    run_privileged swapon "$SWAP_FILE" || error "Failed to swapon"
}

info "💾 Configuring ZRAM to ${ZRAM_PERCENT}% of RAM..."
run_privileged sed -i "s/^PERCENT=.*/PERCENT=${ZRAM_PERCENT}/" /etc/default/zramswap || warn "Failed to update zram config (sed)"
run_privileged systemctl restart zramswap.service || warn "Failed to restart zramswap"

info "🗑️ Checking disk swap configuration..."
if [[ -f "$SWAP_FILE" ]]; then
    # Check if existing swap file is the correct size
    current_size=$(stat -c%s "$SWAP_FILE" 2>/dev/null || echo 0)
    expected_size=$(( DISK_SWAP_SIZE_MB * 1024 * 1024 ))  # Convert MB to bytes

    if [[ $current_size -eq $expected_size ]]; then
        info "✅ Swap file already exists with correct size (${DISK_SWAP_SIZE})"
        # Check if it's already in use
        if swapon --show | grep -q "$SWAP_FILE"; then
            info "✅ Swap file already active"
        else
            info "🔄 Activating existing swap file..."
            run_privileged swapon "$SWAP_FILE" || error "Failed to swapon existing file"
        fi
    else
        warn "Swap file exists but wrong size (current: $((current_size/1024/1024))MB, expected: ${DISK_SWAP_SIZE}). Recreating..."
        run_privileged swapoff "$SWAP_FILE" 2>/dev/null || true
        run_privileged rm -f "$SWAP_FILE" || warn "Failed to remove swapfile"
        create_swap_file
    fi
else
    info "💽 Creating new ${DISK_SWAP_SIZE} swapfile..."
    create_swap_file
fi

# --- POWERTOP CONFIGURATION ---
if command -v powertop > /dev/null 2>&1; then
    SERVICE_NAME="powertop-autotune.service"
    SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

    info "⚡ Powertop found, configuring auto-tune service..."
    [[ -f "$SERVICE_PATH" ]] && warn "$SERVICE_NAME exists. Overwriting..."

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
    run_privileged systemctl enable "$SERVICE_NAME" || warn "Enable failed"
    run_privileged systemctl start "$SERVICE_NAME" || warn "Start failed (may need reboot)"
    ok "Done! Powertop will auto-tune 30s after every boot."
else
    warn "Powertop not found, skipping power optimization setup."
fi

# --- FINAL OUTPUT ---
ok "✅ Done! Active swap devices:"
swapon --show || true
if command -v zramctl >/dev/null; then
    zramctl || true
fi
