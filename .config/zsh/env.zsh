# ~/.config/zsh/env.zsh

typeset -U PATH path

export PATH="$HOME/.local/bin:$PATH"

# Starship uses a generated runtime config so chcolor can switch palettes
# without modifying the yadm-tracked ~/.config/starship.toml.
STARSHIP_RUNTIME_CONFIG="${XDG_CACHE_HOME:-$HOME/.cache}/starship/starship.toml"
if [[ -r "$STARSHIP_RUNTIME_CONFIG" ]]; then
  export STARSHIP_CONFIG="$STARSHIP_RUNTIME_CONFIG"
fi

export EDITOR=micro VISUAL=micro
export PAGER=less
export LESS='-R -F -X'
export BAT_THEME='Catppuccin Mocha'
export BAT_PAGER='less -R'

export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border --info=inline'
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range=:80 {}'"
