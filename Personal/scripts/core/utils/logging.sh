#!/bin/bash

# Logging and utility functions

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok() { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
error() {
    echo -e "${RED}❌ $*${NC}"
    exit 1
}

ensure_file_nonempty() { [[ -f \"$1\" && -s \"$1\" ]]; }
run_privileged() { [ \"$(id -u)\" -eq 0 ] && \"$@\" || sudo \"$@\"; }
run_as_user() { [ \"$EUID\" -eq 0 ] && (ensure_user_context && \"$@\") || \"$@\"; }

ensure_user_context() {
    local target_user=\"${SUDO_USER:-$USER}\"
    if [ \"$EUID\" -eq 0 ] && [ \"$target_user\" != \"root\" ]; then
        export HOME=\"/home/$target_user\"
        cd \"$HOME\" || true
        warn \"Switched context to user: $target_user\"
    fi
}

load_language_env() {
    [[ -s \"$HOME/.cargo/env\" ]] && source \"$HOME/.cargo/env\"
    export PATH=\"$HOME/.bun/bin:$HOME/.local/bin:$PATH\"
}
