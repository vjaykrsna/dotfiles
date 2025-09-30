# Exit early for non-interactive shells
[[ $- != *i* ]] && return

# History
HISTCONTROL=ignoreboth
HISTSIZE=2000
HISTFILESIZE=2000
shopt -s histappend

# Prompt
PS1='\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Color support for ls/grep
eval "$(dircolors -b)"
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Tooling
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# Personal aliases
[[ -f "$HOME/Personal/.alias" ]] && source "$HOME/Personal/.alias"

# Bash completion
[[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion

# Misc
shopt -s checkwinsize
