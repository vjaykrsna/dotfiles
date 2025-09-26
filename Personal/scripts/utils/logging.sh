#!/usr/bin/env bash

# Simple Bash Logging Utility

# Configuration
LOG_FILE="${LOG_FILE:-$(dirname "$(dirname "$0")")/setup.log}"

# Color codes (only if terminal supports colors)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    BLUE=''
    RED=''
    NC=''
fi

# Logging functions with file output
info() {
    echo -e "${BLUE}🔔  $*${NC}"
    # Do not let logging failures break the script; ignore write errors
    echo "INFO: $*" >> "$LOG_FILE" 2>/dev/null || true
}

ok() {
    echo -e "${GREEN}✅ $*${NC}"
    echo "OK: $*" >> "$LOG_FILE" 2>/dev/null || true
}

warn() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    echo "WARN: $*" >> "$LOG_FILE" 2>/dev/null || true
}

error() {
    # Log an error message but do NOT exit — use fatal() when you want to stop execution.
    echo -e "${RED}❌ $*${NC}" >&2
    echo "ERROR: $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Fatal logs and exit: use when you want to stop the script immediately.
fatal() {
    echo -e "${RED}❌ FATAL: $*${NC}" >&2
    echo "FATAL: $*" >> "$LOG_FILE" 2>/dev/null || true
    exit 1
}

debug() {
    echo -e "${BLUE}🐛 $*${NC}"
    echo "DEBUG: $*" >> "$LOG_FILE" 2>/dev/null || true
}

# Progress indicator for long operations
show_progress() {
    local current=$1 total=$2 prefix=${3:-"Progress"}
    if [[ $total -gt 0 ]]; then
        local percent=$((current * 100 / total))
        echo -ne "\r${BLUE}${prefix}: ${percent}%${NC} "
        if [[ $current -eq $total ]]; then
            echo ""  # New line when complete
        fi
    fi
}

# Function to enable robust error handling
set_robust_error_handling() {
    set -euo pipefail
    # On unexpected errors, call fatal() to log and exit. Use error() in code paths
    # where you want to record the problem but continue execution.
    trap 'fatal "Script failed at line $LINENO: Command \`$BASH_COMMAND\` exited with status $?"' ERR
}
