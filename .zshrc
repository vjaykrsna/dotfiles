# ==================================================================
# ENVIRONMENT & PATHS
# ==================================================================
# Only run this file for interactive shells
[[ -o interactive ]] || return

typeset -U PATH path

# History
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# ==================================================================
# SHELL OPTIONS
# ==================================================================
setopt histignorealldups sharehistory extendedhistory incappendhistory histignorespace

# ==================================================================
# COMPLETION
# ==================================================================
skip_global_compinit=1
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=* l:|=*'

# ==================================================================
# ZINIT (minimal plugin set)
# ==================================================================
if [[ -s "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

  zinit ice lucid wait'0' atload'[[ -n $ZLE ]] && zle reset-prompt' silent
  zinit light zdharma-continuum/fast-syntax-highlighting
  zinit ice lucid atinit'zpcompinit; zpcdreplay' silent
  zinit light zsh-users/zsh-completions
  zinit ice lucid wait'0' silent
  zinit light zsh-users/zsh-autosuggestions
  zinit ice lucid wait'0' silent
  zinit light zsh-users/zsh-history-substring-search
  # keybindings for substring search (↑/↓ overwrite)
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  zinit ice lucid turbo wait'0' silent
  zinit light junegunn/fzf
fi

# ==================================================================
# TOOLING
# ==================================================================
# NVM: lazy wrapper moved to ~/Personal/.alias for a single source of truth
# NVM_DIR is exported from ~/.profile

# FZF defaults (fast search)
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Prompt / tools
eval "$(dircolors -b)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
eval "$(thefuck --alias)"

# ==================================================================
# PERSONAL
# ==================================================================
[[ -f "$HOME/Personal/.alias" ]] && source "$HOME/Personal/.alias"

if [[ -s "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
