#!/usr/bin/env bash
# Package Installation Module
# Contains core package management functions

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/bootstrap.sh"

ensure_root_runtime_dir() {
    if [[ "$(id -u)" -ne 0 ]]; then
        return 0
    fi

    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/0}"
    if [[ ! -d "$runtime_dir" ]]; then
        mkdir -p "$runtime_dir"
        chmod 700 "$runtime_dir"
    fi
    export XDG_RUNTIME_DIR="$runtime_dir"
}

install_packages_from_file() {
    # Usage: install_packages_from_file <file> <cmd> [args...]
    # Example: install_packages_from_file "$file" run_privileged apt-get install -y --no-install-recommends
    local file="$1"; shift
    local cmd=("$@")

    if ! ensure_file_nonempty "$file"; then
        return 0
    fi

    info "Installing from $file..."

    # Collect package lines, ignoring comments and blank lines
    mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$file" || true)
    if [ ${#pkgs[@]} -eq 0 ]; then
        info "No packages found in $file"
        return 0
    fi

    # Try batch install (fast); fall back to per-package on failure.
    if command -v "${cmd[0]}" >/dev/null 2>&1; then
        show_progress 0 ${#pkgs[@]} "Installing packages from $(basename "$file")"
        if "${cmd[@]}" "${pkgs[@]}"; then
            show_progress ${#pkgs[@]} ${#pkgs[@]} "Installing packages from $(basename "$file")"
            ok "Installed ${#pkgs[@]} packages from $file"
            return 0
        else
            warn "Batch install failed for $file; falling back to per-package installs"
        fi
    else
        warn "Command ${cmd[0]} not found; falling back to per-package installs"
    fi

    # Fallback to per-package installs
    local installed=0 total=${#pkgs[@]}
    for pkg in "${pkgs[@]}"; do
        show_progress "$installed" "$total" "Installing packages"
        if "${cmd[@]}" "$pkg"; then
            ok "Installed $pkg"
            ((installed++))
        else
            warn "Failed to install $pkg, skipping"
        fi
    done
    show_progress "$total" "$total" "Installing packages"
    [[ $installed -gt 0 ]] && ok "Installed $installed packages from $file"
}

# --- SYSTEM PACKAGES ---
install_system_packages() {
    info "--- System Package Installation ---"

    info "Updating package lists..."
    if command -v apt-get >/dev/null 2>&1; then
        if [ "$(id -u)" -ne 0 ]; then
            sudo -n true 2>/dev/null || sudo true
        fi
        run_privileged apt-get update || fatal "apt-get update failed"
    else
        warn "apt-get not found; skipping apt-get update"
    fi

    info "Installing packages in parallel..."

    # Install apt and flatpak packages in parallel for speed
    install_packages_from_file "$SCRIPT_DIR/../tools/packages/apt.txt" run_privileged apt-get install -y -q --no-install-recommends &
    local apt_pid=$!

    local flatpak_cmd=(flatpak install -y --noninteractive)
    if [[ "$(id -u)" -eq 0 ]]; then
        ensure_root_runtime_dir
        flatpak_cmd+=(--system)
    fi

    install_packages_from_file "$SCRIPT_DIR/../tools/packages/flatpak.txt" "${flatpak_cmd[@]}" &
    local flatpak_pid=$!

    # Wait for both to complete
    wait $apt_pid
    wait $flatpak_pid

    ok "Package installations completed"

    local custom_file="$SCRIPT_DIR/../tools/packages/custom.sh"
    local last_run_flag="/var/tmp/custom.sh.last_run"
    if [[ -f "$custom_file" ]]; then
        mkdir -p "$(dirname "$last_run_flag")" 2>/dev/null || true
        if [[ ! -f "$last_run_flag" || "$(stat -c %Y "$custom_file" 2>/dev/null || echo 0)" -gt "$(stat -c %Y "$last_run_flag" 2>/dev/null || echo 0)" ]]; then
            run_privileged bash "$custom_file"
            touch "$last_run_flag"
            ok "Custom script executed (changes detected)"
        else
            info "Custom script skipped (no changes since last run)"
        fi
    fi
}
