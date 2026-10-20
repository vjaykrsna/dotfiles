# dotfiles — Termux branch

This branch is the Termux side of `vjaykrsna/dotfiles`. The `desktop` branch is
the default desktop setup; `termux` is an orphan branch with phone-only configs.

## Restore on a fresh Termux install

```bash
pkg install -y yadm
yadm clone --no-bootstrap -b termux https://github.com/vjaykrsna/dotfiles.git
yadm bootstrap
exec zsh
```

`yadm bootstrap` runs `~/bootstrap.sh` through
`~/.config/yadm/bootstrap`. The script installs packages, zinit, the JetBrains
Mono Nerd Font Mono, creates the SSH key if missing, and applies Catppuccin
Mocha. It does not store private keys or tokens. Running `./bootstrap.sh`
directly also works. For a no-package-install preflight, use
`BOOTSTRAP_SKIP_PACKAGES=1 ./bootstrap.sh`.

## What is managed

- `~/.zshrc` and modular `~/.config/zsh/{env,plugins,aliases,functions}.zsh`
- Starship prompt with active Python, Node, Rust, Go, and Java modules
- fastfetch login banner and config
- Termux extra-keys and Catppuccin color schemes
- `chcolor` theme switcher (Mocha, Macchiato, Frappe, Latte)
- yt-dlp share opener saving to `Download/Termux`
- SSH client config (key generated locally, never committed)
- micro settings
- `.hushlogin`
- `~/.config/yadm/bootstrap` wrapper for `yadm bootstrap`

## Theme switching

```bash
chcolor mocha
chcolor macchiato
chcolor frappe
chcolor latte
chcolor list
```

Fonts are not switched; JetBrains Mono stays installed. Starship uses a
generated runtime config in `~/.cache/starship/starship.toml`, so changing the
theme does not dirty the tracked config.

## Share to Termux

Share a video URL to Termux. The opener uses `yt-dlp` with best video+audio,
SponsorBlock removal, and saves under `~/storage/shared/Download/Termux`.

## Not restored by this branch

- The native OpenCode install under `~/agents/opencode` and its config under
  `~/.config/opencode` are deliberately not stored here. Reinstall or restore
  them separately before wiping Termux app data.
- GitHub CLI authentication is not stored. Run `gh auth login` again.
- The SSH key is generated new by bootstrap; add the new public key where needed.
- Android shared-storage access must be granted again with `termux-setup-storage`.

## Notes

- No backup snapshots are kept. yadm history is the rollback mechanism.
- Runtime state, the font, `colors.properties`, storage links, and SSH private
  keys are ignored by yadm.
