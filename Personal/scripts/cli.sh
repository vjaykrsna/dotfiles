#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --- Sourcing Dependencies ---
source ./scripts/installer.sh # For logging and utility functions

run_cli_installer_interactive() {
	# --- TOOLS ---
	declare -A tools=(
		[1]="Qwen Code:@qwen-code/qwen-code@latest"
		[2]="Google Gemini CLI:@google/gemini-cli"
		[3]="Charmland Crush:@charmland/crush"
	)

	# --- SHOW MENU ---
	show_menu() {
		info "╔════ CLI Tools Installer ════╗"
		for i in "${!tools[@]}"; do
			echo -e "${BLUE}║${NC} ${YELLOW}$i.${NC} ${tools[$i]%%:*}"
		done
		echo -e "${BLUE}║${NC} ${GREEN}q.${NC} Quit${NC}"
		echo -ne "${YELLOW}Enter choice(s) (space/comma separated): ${NC}"
	}

	# --- INSTALL TOOL ---
	install_tool() {
		local num=$1
		local name="${tools[$num]%%:*}"
		local pkg="${tools[$num]#*:}"

		if command -v "${name,,}" >/dev/null 2>&1; then
			warn "⚡ $name already installed."
			return
		fi

		info "🔧 Installing $name..."
		if npm install -g "$pkg"; then
			ok "$name installed!"
		else
			error "Failed to install $name. Try running with sudo if needed."
		fi
	}

	# --- PARSE INPUT ---
	parse_and_execute() {
		local input="$1"
		if [[ "$input" =~ ^[0-9]+$ ]]; then
			for ((i = 0; i < ${#input}; i++)); do
				local n="${input:i:1}"
				[[ -n "${tools[$n]}" ]] && install_tool "$n"
			done
		fi
	}

	# --- MAIN LOOP ---
	while true; do
		show_menu
		read -r choice
		[[ "$choice" =~ ^[qQ]$ ]] && warn "👋 Goodbye!" && break
		parse_and_execute "$choice"
		echo
		read -rp "Press Enter to continue..."
		echo
	done
}

# Allow running standalone or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	run_cli_installer_interactive
fi
