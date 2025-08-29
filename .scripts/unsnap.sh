#!/bin/bash
set -e

echo "🚨 Make sure you have backups! This will remove snap and its packages."

# Step 1: List all installed snaps
echo "Installed snaps:"
snap list

# Step 2: Remove all snap packages
echo "Removing all snap packages..."
for snap in $(snap list | awk 'NR>1 {print $1}'); do
    echo "Removing $snap..."
    sudo snap remove "$snap" || echo "Could not remove $snap, maybe required by another snap."
done

# Step 3: Stop snap services
echo "Stopping snap services..."
sudo systemctl stop snapd
sudo systemctl disable snapd

# Step 4: Remove snapd
echo "Removing snapd..."
sudo apt purge snapd -y

# Step 5: Remove leftover directories
echo "Cleaning leftover snap directories..."
rm -rf ~/snap
sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd

echo "✅ Snap and all its packages removed."
