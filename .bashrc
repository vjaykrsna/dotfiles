#!/usr/bin/env bash

# Exit early for non-interactive shells
[[ $- != *i* ]] && return

# -----------------------------
# History (shared with zsh)
# -----------------------------
HISTFILE="$HOME/.zsh_history"
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend

__sync_history() { history -a; history -n; }
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}__sync_history"

# -----------------------------
# Prompt & terminal
# -----------------------------
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
    *) color_prompt=no;;
esac

# Guard against missing /etc/debian_chroot
if [[ -z ${debian_chroot:-} && -f /etc/debian_chroot ]]; then
    debian_chroot=$(< /etc/debian_chroot)
else
    debian_chroot=""
fi

if [[ $color_prompt == yes ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

case "$TERM" in
    xterm*|rxvt*) PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1";;
esac

# -----------------------------
# Color support for ls/grep
# -----------------------------
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b "${HOME}/.dircolors" 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# -----------------------------
# Personal aliases & scripts
# -----------------------------
[[ -f "$HOME/Personal/.alias" ]] && source "$HOME/Personal/.alias"

# -----------------------------
# Bash completion
# -----------------------------
if ! shopt -oq posix; then
    [[ -f /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion
    [[ -f /etc/bash_completion ]] && source /etc/bash_completion
fi

# -----------------------------
# Runtime managers
# (moved common helpers to ~/Personal/.alias)
# NVM_DIR is exported from ~/.profile
# -----------------------------

# -----------------------------
# Misc helpful options
# -----------------------------
shopt -s checkwinsize
