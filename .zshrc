# ==================================================================
# STARTUP PROFILING
# ==================================================================
_zsh_start_time=${_zsh_start_time:-$EPOCHREALTIME}

# ==================================================================
# ENVIRONMENT & PATHS
# ==================================================================
typeset -U PATH path  # De-duplicate PATH with KSH arrays
path=(
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
    "$HOME/go/bin"
    /usr/local/bin
    /usr/bin
    /bin
    $path
)
export EDITOR="micro"
export VISUAL="code"

# History
export HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# ==================================================================
# FASTER STARTUP / COMPLETION CACHE
# ==================================================================
skip_global_compinit=1
zstyle ':completion:*' use-cache on
ZSH_CACHE_DIR="$HOME/.zsh/cache"
mkdir -p "$ZSH_CACHE_DIR"
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"

# ==================================================================
# SHELL OPTIONS
# ==================================================================
setopt histignorealldups sharehistory extendedhistory incappendhistory histignorespace

# ==================================================================
# COMPLETION STYLING
# ==================================================================
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=* l:|=*'

# ==================================================================
# ZINIT - PLUGIN MANAGER
# ==================================================================
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Syntax Highlighting
zinit ice lucid wait'0' atload'[[ -n $ZLE ]] && zle reset-prompt' silent
zinit light zdharma-continuum/fast-syntax-highlighting

# Completions
zinit ice lucid atinit'zpcompinit; zpcdreplay' silent
zinit light zsh-users/zsh-completions

# Autosuggestions
zinit ice lucid wait'0' silent
zinit light zsh-users/zsh-autosuggestions

# FZF + fzf-tab
zinit ice lucid turbo wait'0' silent
zinit light junegunn/fzf
zinit ice lucid turbo wait'0' silent
zinit light Aloxaf/fzf-tab

# OMZ Plugins
zinit ice lucid turbo silent
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit ice lucid turbo silent
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# Compile plugins for faster startup
zinit compile --all @>/dev/null

# ==================================================================
# TOOLING & INTEGRATIONS
# ==================================================================

# Lazy-load NVM
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
load_nvm() {
  unalias nvm node npm npx nodesymlink 2>/dev/null
  unset -f load_nvm
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

  autoload -U add-zsh-hook
  load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc)"
    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version="$(nvm version "$(cat "$nvmrc_path")")"
      if [ "$nvmrc_node_version" = "N/A" ]; then nvm install
      elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then nvm use
      fi
    elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && \
         [ "$(nvm version)" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc

  "$@"
}
alias nvm='load_nvm nvm'

# Lazy-load pyenv
export PYENV_ROOT="$HOME/.pyenv"
_pyenv_init_run=0
load_pyenv() {
  if [ "$_pyenv_init_run" -eq 0 ]; then
    eval "$(pyenv init -)"
    _pyenv_init_run=1
  fi
  unalias pyenv 2>/dev/null
  pyenv "$@"
}
alias pyenv="load_pyenv"

# FZF defaults
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND="fd --type f"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Performance benchmark alias
alias zshtime='time zsh -ic exit 2>/dev/null | head -2'

# Prompt / Zoxide / Dircolors
eval "$(dircolors -b)"
eval "$(zoxide init zsh)"

# Starship Prompt
eval "$(starship init zsh)"

# TheFuck (with caching for faster startup)
_THE_FUCK_CACHE="${ZSH_CACHE_DIR:-$HOME/.zsh/cache}/thefuck.zsh"
if [[ ! -f "$_THE_FUCK_CACHE" || "$_THE_FUCK_CACHE" -ot "$(which thefuck 2>/dev/null)" ]]; then
    mkdir -p "${_THE_FUCK_CACHE:h}"
    thefuck --alias > "$_THE_FUCK_CACHE" 2>/dev/null
fi
source "$_THE_FUCK_CACHE" 2>/dev/null

# ==================================================================
# PERSONAL ALIASES
# ==================================================================
# Load personal aliases from dedicated file
[[ -f "$HOME/Personal/.aliases" ]] && source "$HOME/Personal/.aliases"

# ==================================================================
# FINISH STARTUP PROFILING
# ==================================================================
if [[ -n "$_zsh_start_time" ]]; then
    _zsh_startup_time=$((EPOCHREALTIME - _zsh_start_time))
    printf '\e[2m%.3fs startup time\e[0m\n' "$_zsh_startup_time"
    unset _zsh_start_time
fi

# ==================================================================
# FUNCTIONS
# ==================================================================
fpath=($HOME/Personal/functions $fpath)
autoload -U extract dockerctl nodesymlink termux yadma cleanup install_appimage addsubmodule

# bun completions
[ -s "/home/vijay/.bun/_bun" ] && source "/home/vijay/.bun/_bun"
