#!/usr/bin/env bash

# -----------------------------
# Login shell bootstrap
# -----------------------------
[[ -f "$HOME/.profile" ]] && source "$HOME/.profile"

# -----------------------------
# Interactive shell adjustments
# -----------------------------
if [[ $- == *i* ]] && [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
