# Personal Setup Scripts

## Overview
This folder contains modular bash scripts for setting up and maintaining a lean Ubuntu/Debian-based Linux environment with GNOME, zsh, and development tools. Scripts focus on idempotency, minimal interactions, and integration with yadm (for dotfiles) and dconf (for GNOME settings). Designed for consistency across machines.

- **Philosophy**: Lean installs (e.g., --no-install-recommends), no unnecessary checks/interactives, error handling with set -euo pipefail.
- **Shell**: Bash scripts; for zsh, add aliases in ~/.zshrc (e.g., `alias setup='cd ~/Personal/scripts/setup && ./setup.sh'`).
- **Dependencies**: sudo, git, curl, apt. Run as non-root unless specified.
- **Yadm/Dconf**: Commit changes post-run (e.g., yadm add .config/dconf). Use gnome-settings.sh for GNOME sync.

## Structure
- **core/**: Shared utilities (installer.sh, utils/logging.sh).
- **setup/**: Main flows (pre-install.sh, setup.sh, post-install.sh).
- **maintenance/**: Hardware/fixes (fixes.sh, myconfig.sh, nvidia.sh, snap-removal.sh).
- **sync/**: Backups/restores (package-sync.sh, gnome-extensions.sh, gnome-settings.sh, system-sync.sh).
- **tools/**: Installers (cli.sh, nerd-fonts.sh) and packages/ (lists for apt, npm, etc.).

## Usage & Run Order
1. **Prep**: `./setup/pre-install.sh` (sudo) – Update system, install essentials.
2. **Main Setup**: `./setup/setup.sh` (menu or --all for automated).
   - Installs packages, languages (Node/Rust/Bun), shell env, fixes, configs.
   - Calls: system packages, language env, CLI tools, NVIDIA (if applicable), post-install.
3. **Post**: `./setup/post-install.sh` (sudo) – Themes, repos, plugins.
4. **Sync (Source Machine)**: `./sync/package-sync.sh` – Save package lists to tools/packages/.
5. **Restore (New Machine)**: Run setup.sh, then `./sync/gnome-settings.sh load`, `./sync/gnome-extensions.sh install`.
6. **Maintenance**:
   - Fonts: `./tools/nerd-fonts.sh`
   - NVIDIA: `./maintenance/nvidia.sh` or `./maintenance/nvidia.sh revert`
   - Snap Removal: `./maintenance/snap-removal.sh`
   - Fixes: `./maintenance/fixes.sh all`

For full automated: `./setup/setup.sh all` (after pre-install).

## Script Details
- **core/installer.sh**: Logging, package installs from lists. Sourced by most scripts.
- **setup/pre-install.sh**: Apt update/upgrade, essentials, Flatpak setup.
- **setup/setup.sh**: Orchestrator menu/automated. Sources core/installer.sh.
- **setup/post-install.sh**: Flathub, themes (Sekiro GRUB, Adwaita), Micro plugins.
- **maintenance/fixes.sh**: Input-remapper, udev, SSSD disable.
- **maintenance/myconfig.sh**: ZRAM (200%), swap (1.5x RAM), powertop autotune.
- **maintenance/nvidia.sh**: Switch to integrated (on-demand); revert flag.
- **maintenance/snap-removal.sh**: Purge snapd and packages.
- **sync/package-sync.sh**: Save lists (apt, flatpak, npm, etc.) to tools/packages/.
- **sync/gnome-extensions.sh**: Save/install enabled extensions via gext.
- **sync/gnome-settings.sh**: Dump/load dconf (/org/gnome/); diff mode.
- **sync/system-sync.sh**: Backup/diff crontab, fstab, hosts.
- **tools/cli.sh**: Install CLI tools (Qwen, Gemini, Crush) via npm; --all flag.
- **tools/nerd-fonts.sh**: Download/install Nerd Fonts (array: JetBrainsMono, FiraCode, GeistMono, Hack, MesloLGS); cleanup extras.
- **tools/packages/**: Txt files for restores (run xargs apt install -y < apt.txt, etc.).

## Notes
- **Zsh**: Scripts are bash; test in zsh with `bash script.sh`. Post-setup: exec zsh.
- **NVIDIA**: Requires nvidia-prime; reverts with --reset.
- **Custom**: tools/packages/custom.sh handles Chrome, Docker (uses lsb_release -cs), VS Code, OnlyOffice, auto-cpufreq.
- **Errors**: Scripts exit on failure; check journalctl -xe.
- **Updates**: Run package-sync.sh on source, commit to yadm.

## Logging contract (short)

- `info "..."` — Informational messages about progress.
- `ok "..."` — Success messages for completed steps.
- `warn "..."` — Non-fatal warnings; script continues.
- `error "..."` — Non-fatal error logging; reports the issue but does NOT exit.
- `fatal "..."` — Logs the error and exits immediately (use when the rest of the script cannot proceed).

Notes on traps: scripts use `set -euo pipefail` and the global ERR trap calls `fatal()` so unexpected command failures are logged and terminate the script. Use `error()` for recoverable errors where the script should continue.

Recent changes: standardized logging functions (`error` is now non-fatal; `fatal` was added) and updated the scripts to use `fatal` for critical failures and `warn`/`error` for recoverable issues.

For issues, check logs or run sections individually.
