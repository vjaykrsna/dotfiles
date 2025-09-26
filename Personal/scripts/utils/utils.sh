#!/usr/bin/env bash
# Ensure logging is loaded for warn/info functions
if ! declare -f warn >/dev/null; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [ -f "$SCRIPT_DIR/logging.sh" ]; then
        source "$SCRIPT_DIR/logging.sh"
    fi
fi

# Utility functions

append_trap() {
    local cmd="$1"
    shift || return
    for sig in "$@"; do
        local existing
        existing=$(trap -p "$sig" 2>/dev/null | sed "s/^'//; s/'$//")
        if [[ -n "$existing" ]]; then
            local new_cmd="$existing; $cmd"
        else
            local new_cmd="$cmd"
        fi
        eval "trap -- '$new_cmd' $sig"
    done
}

ensure_runtime_tmpdir() {
    if [[ -z "${SETUP_TMPDIR:-}" || ! -d "$SETUP_TMPDIR" ]]; then
        SETUP_TMPDIR=$(mktemp -d /tmp/dotfiles-setup-XXXXXX)
        append_trap "rm -rf \"$SETUP_TMPDIR\"" EXIT
    fi
    export SETUP_TMPDIR
}

ensure_sudo() {
    if [[ "$(id -u)" -eq 0 ]]; then
        return 0
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        fatal "sudo command not found. Please run as root."
    fi
    sudo -v || fatal "Unable to obtain sudo privileges."
}

ensure_file_nonempty() { [[ -f "$1" && -s "$1" ]]; }
run_privileged() { if [ "$(id -u)" -eq 0 ]; then "$@"; else ensure_sudo && sudo "$@"; fi }
run_as_user() { if [ "$EUID" -eq 0 ]; then ensure_user_context && "$@"; else "$@"; fi }

ensure_user_context() {
    local target_user="${SUDO_USER:-$USER}"
    if [ "$EUID" -eq 0 ] && [ "$target_user" != "root" ]; then
        export HOME="/home/$target_user"
        cd "$HOME" || true
        warn "Switched context to user: $target_user"
    fi
}

load_language_env() {
    [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"
}

check_basic_dependencies() {
    info "Checking basic dependencies..."
    local deps=(git curl jq git-lfs)
    local missing=()
    for dep in "${deps[@]}"; do
        ! command -v "$dep" &> /dev/null && missing+=("$dep")
    done
    if [[ "${#missing[@]}" -gt 0 ]]; then
        error "Missing dependencies: ${missing[*]}"
        error "Please install: sudo apt install ${missing[*]}"
        fatal "Required dependencies are missing"
    fi
    ok "Basic dependencies satisfied."
}

# --- Helpers for fixes.sh (healer helpers)
ensure_group_exists() {
    local grp="$1"
    info "Ensuring group exists: $grp"
    if run_privileged groupadd -f "$grp" >/dev/null 2>&1; then
        ok "Group ensured: $grp"
        return 0
    else
        warn "Could not fully ensure group $grp (check permissions)"
        return 1
    fi
}

ensure_user_in_group() {
    local user="$1" grp="$2"
    if id -nG "$user" | grep -qw "$grp"; then
        info "$user is already in group $grp"
        return 0
    fi
    info "Adding $user to group $grp"
    if run_privileged usermod -a -G "$grp" "$user"; then
        ok "Added $user to $grp"
        return 1
    else
        error "Failed to add $user to $grp"
        return 2
    fi
}

ensure_systemd_override() {
    local service="$1" content="$2"
    local dir="/etc/systemd/system/${service}.d"
    local file="$dir/override.conf"
    info "Writing systemd override for ${service} -> ${file}"
    if ! run_privileged mkdir -p "$dir"; then
        error "Could not create directory $dir"
        return 2
    fi
    if printf "%s\n" "$content" | run_privileged tee "$file" >/dev/null; then
        ok "Wrote systemd override: $file"
        return 0
    else
        error "Failed to write systemd override to $file"
        return 3
    fi
}

ensure_udev_rule() {
    local file="$1" rule="$2"
    info "Installing udev rule -> $file"
    if ! run_privileged mkdir -p "$(dirname "$file")"; then
        error "Could not create directory $(dirname "$file")"
        return 2
    fi
    if printf "%s\n" "$rule" | run_privileged tee "$file" >/dev/null; then
        ok "Wrote udev rule: $file"
        return 0
    else
        error "Failed to write udev rule to $file"
        return 3
    fi
}

download_and_exec() {
    local url="$1" tmp_name="$2" exec_cmd="$3"
    local temp_file
    temp_file=$(mktemp "$SETUP_TMPDIR/install-$tmp_name.XXXXXX") || fatal "Failed to create temp file for $tmp_name installer"
    if curl -fsSL "$url" -o "$temp_file"; then
        if eval "$exec_cmd \"$temp_file\""; then
            info "$tmp_name installed"
        else
            warn "$tmp_name install script failed"
        fi
        rm -f "$temp_file"
    else
        warn "Failed to download $tmp_name installer"
    fi
}

# Generic sync helpers
save_resource() {
    local resource="$1" file="$2" cmd="$3"
    info "Saving $resource to $file..."
    mkdir -p "$(dirname "$file")"
    eval "$cmd" > "$file" || fatal "Failed to save $resource"
    ok "$resource saved."
}

load_resource() {
    local resource="$1" file="$2" cmd="$3"
    if [[ ! -f "$file" ]]; then
        fatal "File not found for $resource"
    fi
    info "Loading $resource from $file..."
    eval "$cmd < \"$file\"" || fatal "Failed to load $resource"
    ok "$resource loaded."
}

diff_resource() {
    local resource="$1" file="$2" cmd="$3"
    if [[ ! -f "$file" ]]; then
        fatal "File not found for $resource"
    fi
    info "Diffing $resource..."
    eval "diff -u <($cmd) \"$file\"" || true
}
