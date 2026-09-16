#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_HOME=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-home.XXXXXX")
trap 'find "$TMP_HOME" -depth -type f -delete 2>/dev/null || true; find "$TMP_HOME" -depth -type d -empty -delete 2>/dev/null || true' EXIT

HOME="$TMP_HOME" DOTFILES_ASSUME_YES=1 "$ROOT_DIR/install.sh" --mode safe >/tmp/dotfiles-smoke.log 2>&1

for path in .bashrc .bash_profile .profile .zshrc .zprofile .vimrc .tmux.conf .config/nvim/init.lua .config/nvim/lua/custom_dashboard.lua .config/dotfiles/profile; do
  [ -f "$TMP_HOME/$path" ] || { printf 'missing installed file: %s\n' "$path" >&2; exit 1; }
done

[ "$(cat "$TMP_HOME/.config/dotfiles/profile")" = safe ]

HOME="$TMP_HOME" DOTFILES_PROFILE=safe /bin/bash -n "$TMP_HOME/.bashrc"
HOME="$TMP_HOME" DOTFILES_PROFILE=safe /bin/zsh -n "$TMP_HOME/.zshrc"
printf '%s\n' 'smoke: OK'
