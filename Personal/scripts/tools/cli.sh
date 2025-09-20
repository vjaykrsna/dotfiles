#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Source dependencies only when running standalone ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    source "../core/installer.sh" # For logging and utility functions
fi

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

    # --- Menu display ---
    show_menu() {
        info "╔════ CLI Tools Installer ════╗"
        for i in "${!tools[@]}"; do
            echo -e "║ $i. ${tools[$i]%%:*}"
        done
        echo -e "║ q. Quit"
        echo -ne "Enter choice(s): "
    }

    # --- Install or update a tool and show version change ---
    install_tool() {
        local num=$1
        IFS=':' read -r name pkg bin <<< "${tools[$num]}"

        # Get old version if installed
        local old_version=""
        if command -v "$bin" &> /dev/null; then
            old_version=$("$bin" --version 2>&1)
        fi

        info "🔧 Installing/updating $name..."
        if npm install -g "$pkg"; then
            ok "$name installed/updated!"
        else
            error "Failed to install $name. Try running with sudo if needed."
            return
        fi

        # Get new version
        local new_version=""
        if command -v "$bin" &> /dev/null; then
            new_version=$("$bin" --version 2>&1)
        fi

        # Print version change
        if [[ -n "$old_version" ]]; then
            echo "ℹ️  $name updated: $old_version → $new_version"
        else
            echo "ℹ️  $name installed: $new_version"
        fi
    }

    # --- Parse and execute user input ---
    parse_and_execute() {
        local input="$1"
        for ((i=0; i<${#input}; i++)); do
            local n="${input:i:1}"
            [[ -n "${tools[$n]}" ]] && install_tool "$n"
        done
    }

    # --- Main interactive loop ---
    while true; do
        show_menu
        read -r choice
        [[ "$choice" =~ ^[qQ]$ ]] && warn "👋 Goodbye!" && break
        parse_and_execute "$choice"
        echo
    done
}

# --- Run standalone ---
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_cli_installer "$1"
