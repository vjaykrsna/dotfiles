#!/data/data/com.termux/files/usr/bin/bash
# Rebuild the Termux side of this dotfiles branch after a fresh install.
# Run from ~ after cloning the `termux` branch with yadm.
set -euo pipefail

say() { printf '\n==> %s\n' "$*"; }

if [[ -z "${BOOTSTRAP_SKIP_PACKAGES:-}" ]]; then
  say "Installing Termux packages"
  pkg install -y \
    zsh starship micro eza bat fzf zoxide jq git-delta fastfetch tealdeer \
    yazi gh yadm uv ruff pnpm nodejs-lts rust golang sqlite python-yt-dlp yt-dlp-ejs \
    openssh ffmpeg curl
else
  say "Skipping package installation (BOOTSTRAP_SKIP_PACKAGES is set)"
fi

say "Preparing directories"
mkdir -p \
  "$HOME/.local/bin" \
  "$HOME/.config/zsh" \
  "$HOME/.termux/colors" \
  "$HOME/.termux/bin" \
  "$HOME/.ssh"

chmod 700 "$HOME/.ssh"

say "Installing zinit"
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME/.git" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

say "Installing JetBrains Mono Nerd Font Mono"
FONT="$HOME/.termux/font.ttf"
if [[ ! -s "$FONT" ]]; then
  curl -fL --retry 3 --retry-delay 2 \
    -o "${FONT}.download" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/JetBrainsMono/NoLigatures/JetBrainsMonoNLNerdFontMono-Regular.ttf"
  mv "${FONT}.download" "$FONT"
fi

say "Linking the URL opener and shell"
ln -sfn ../termux-url-opener "$HOME/.termux/bin/termux-url-opener"
ln -sfn "$PREFIX/bin/zsh" "$HOME/.termux/shell"
chmod +x "$HOME/.local/bin/chcolor" "$HOME/.termux/termux-url-opener"
touch "$HOME/.hushlogin"

if [[ -d "$HOME/storage/shared" ]]; then
  mkdir -p "$HOME/storage/shared/Download/Termux"
else
  echo "Storage is not linked yet. Run: termux-setup-storage"
fi

say "Generating an SSH key (no passphrase)"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "termux@$(uname -n 2>/dev/null || echo termux)" \
    -f "$HOME/.ssh/id_ed25519" -N ""
fi

say "Applying Catppuccin Mocha"
"$HOME/.local/bin/chcolor" mocha

if command -v termux-reload-settings >/dev/null 2>&1; then
  termux-reload-settings || true
fi

say "Done"
cat <<'EOF'

Next steps:
  1. If GitHub is not configured:
       gh auth login --web --git-protocol https
  2. If storage is not linked:
       termux-setup-storage
  3. Start a fresh shell:
       exec zsh

The SSH public key is at ~/.ssh/id_ed25519.pub.
The yt-dlp share target is ~/storage/shared/Download/Termux.
EOF
