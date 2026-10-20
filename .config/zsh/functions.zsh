# ~/.config/zsh/functions.zsh

mkcd() {
  mkdir -p "$1" && cd "$1"
}

rish() {
  "$HOME/.rish/rish" "$@"
}
