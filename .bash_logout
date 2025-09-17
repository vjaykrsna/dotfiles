# ~/.bash_logout: executed by bash(1) when login shell exits.
# Clear the screen on logout for top-level interactive login shells only.
# This avoids clearing when scripts or nested shells exit.

# Only run for interactive shells and when SHLVL indicates a top-level shell.
if [ -n "$PS1" ] || [ -t 1 ]; then
    if [ "${SHLVL:-0}" -eq 1 ]; then
        if command -v clear_console >/dev/null 2>&1; then
            clear_console -q || true
        elif command -v tput >/dev/null 2>&1; then
            tput reset || true
        else
            # ANSI fallback
            printf '\033c'
        fi
    fi
fi
