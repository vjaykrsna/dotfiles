#!/usr/bin/env bash
# cli.sh - Interactive CLI tools installer helper
# Usage: source cli.sh && run_cli_installer_interactive
# Example: ./cli.sh
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/../utils/bootstrap.sh"

run_cli_installer() {
    if [[ "${1:-}" == "--all" ]]; then
        info "Installing all CLI tools..."
        parse_and_execute "123"
        ok "All CLI tools installed."
        return
    fi
    run_cli_installer_interactive
}

run_cli_installer_interactive() {
    # --- Tools and npm packages ---
    declare -A tools=(
        [1]="Qwen Code:@qwen-code/qwen-code@nightly:qwen"
        [2]="Google Gemini CLI:@google/gemini-cli@preview:gemini"
        [3]="Charmland Crush:@charmland/crush:crush"
    )

    # --- Main interactive loop ---
    while true; do
        select opt in "${tools[*]%%:*}" Quit; do
            if [[ $REPLY == $(( ${#tools[@]} + 1 )) ]]; then
                warn "👋 Goodbye!"
                break 2
            fi
            if [[ $REPLY -ge 1 && $REPLY -le ${#tools[@]} ]]; then
                local num=$REPLY
                install_tool "$num"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done
    done
}

# --- Run standalone ---
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_cli_installer "$1"
