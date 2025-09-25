#!/usr/bin/env bash
# Global configuration defaults for dotfiles setup scripts.

# Ensure CONFIG is a global associative array
if ! declare -p CONFIG >/dev/null 2>&1; then
    declare -gA CONFIG=()
fi

# Populate defaults only when not already set
CONFIG[ZRAM_PERCENT]="${CONFIG[ZRAM_PERCENT]:-200}"
CONFIG[SWAP_MULTIPLIER]="${CONFIG[SWAP_MULTIPLIER]:-1.5}"
CONFIG[NVM_VERSION]="${CONFIG[NVM_VERSION]:-0.40.3}"
CONFIG[RUSTUP_DEFAULT_TOOLCHAIN]="${CONFIG[RUSTUP_DEFAULT_TOOLCHAIN]:-stable}"
