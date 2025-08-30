#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- COLORS ---
GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- TOOLS ---
declare -A tools=(
    [1]="Qwen Code:@qwen-code/qwen-code@latest"
    [2]="Google Gemini CLI:@google/gemini-cli"
    [3]="Charmland Crush:@charmland/crush"
)

# --- SHOW MENU ---
show_menu() {
    echo -e "${BLUE}╔════ CLI Tools Installer ════╗${NC}"
    for i in "${!tools[@]}"; do
        echo -e "${BLUE}║${NC} ${YELLOW}$i.${NC} ${tools[$i]%%:*}"
    done
    echo -e "${BLUE}║${NC} ${GREEN}q.${NC} Quit${NC}"
    echo -ne "${CYAN}Enter choice(s) (space/comma separated): ${NC}"
}

# --- INSTALL TOOL ---
install_tool() {
    local num=$1
    local name="${tools[$num]%%:*}"
    local pkg="${tools[$num]#*:}"

    if command -v "${name,,}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚡ $name already installed.${NC}"
        return
    fi

    echo -e "${GREEN}🔧 Installing $name...${NC}"
    if npm install -g "$pkg"; then
        echo -e "${GREEN}✅ $name installed!${NC}"
    else
        echo -e "${RED}❌ Failed to install $name. Try running with sudo if needed.${NC}"
    fi
}

# --- PARSE INPUT ---
parse_and_execute() {
    local input="$1"
    # Handle concatenated numbers like "123"
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        for ((i=0; i<${#input}; i++)); do
            local n="${input:i:1}"
            [[ -n "${tools[$n]}" ]] && install_tool "$n"
        done
    fi
}

# --- MAIN LOOP ---
while true; do
    show_menu
    read -r choice
    [[ "$choice" =~ ^[qQ]$ ]] && echo -e "${YELLOW}👋 Goodbye!${NC}" && break
    parse_and_execute "$choice"
    echo; read -rp "Press Enter to continue..."; echo
done
