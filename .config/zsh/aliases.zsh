# ~/.config/zsh/aliases.zsh

# --- navigation ----------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- files ---------------------------------------------------------------
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --style=plain --paging=never'
alias grep='rg'
alias find='fd'

# --- tools ---------------------------------------------------------------
alias fetch='fastfetch'
alias df='df -h'
alias free='free -h'
alias reload='termux-reload-settings'
alias update='pkg update && pkg upgrade'
alias y='yazi'

# --- git -----------------------------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 10'
