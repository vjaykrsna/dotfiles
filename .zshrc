# ~/.zshrc — Termux zsh entry point
# Modules live in ~/.config/zsh/{env,plugins,aliases,functions}.zsh

[[ -o interactive ]] || return

# --- history -------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS SHARE_HISTORY \
       EXTENDED_HISTORY INC_APPEND_HISTORY HIST_IGNORE_SPACE

# --- completion colors ---------------------------------------------------
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

# --- completion styles ---------------------------------------------------
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}%d%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

# --- keybindings ---------------------------------------------------------
bindkey -e

# --- modules -------------------------------------------------------------
for _module in env plugins aliases functions; do
  [[ -r "$HOME/.config/zsh/${_module}.zsh" ]] && source "$HOME/.config/zsh/${_module}.zsh"
done
unset _module

# --- fastfetch: every new Termux session (login shell) -------------------
# Set TERMUX_NO_FASTFETCH=1 to disable.
if [[ -o login ]] && [[ -o interactive ]] && [[ -z "$TERMUX_NO_FASTFETCH" ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi
