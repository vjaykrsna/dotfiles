# ~/.profile: executed by login shells

# -----------------------------
# PATH setup
# -----------------------------
# Deduplicated paths for login shells
prepend_path() {
    for p in "$@"; do
        [[ -d "$p" && ":$PATH:" != *":$p:"* ]] && PATH="$p:$PATH"
    done
}

prepend_path \
    "$HOME/bin" \
    "$HOME/.local/bin" \
    "$HOME/.bun/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/go/bin" \
    "$HOME/.pyenv/bin"

export PATH

# Editor defaults for all shells
export EDITOR="micro"
export VISUAL="code"
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"

# -----------------------------
# Cargo environment (if exists)
# -----------------------------
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
