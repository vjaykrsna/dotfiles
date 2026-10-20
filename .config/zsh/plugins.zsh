# ~/.config/zsh/plugins.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
_has_zinit=0
if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
  _has_zinit=1
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-history-substring-search
  zinit light zsh-users/zsh-completions
fi

fpath=("$PREFIX/share/zsh/site-functions" $fpath)
autoload -Uz compinit && compinit -i

if (( _has_zinit )); then
  zinit light Aloxaf/fzf-tab
  zinit light zdharma-continuum/fast-syntax-highlighting
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi
unset _has_zinit

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi
