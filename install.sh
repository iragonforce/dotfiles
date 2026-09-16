#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MODE=""
DRY_RUN=0
INSTALL_ROOT=0
FULL_APPS=0
BACKUP_ROOT=""
FAILED=()
SKIPPED=()
INSTALLED=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--mode safe|essential|mirror] [--dry-run] [--install-root]

safe      copy configuration only; no network, package manager, sudo, or plugins
essential install core packages when available, without third-party frameworks
mirror    install the curated toolchain and declared frameworks/plugins
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }
log() { printf '\033[1;32m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*" >&2; }
error() { printf '\033[1;31m[dotfiles]\033[0m %s\n' "$*" >&2; }
record_failed() { FAILED+=("$*"); error "$*"; }
record_skipped() { SKIPPED+=("$*"); warn "$*"; }
record_installed() { INSTALLED+=("$*"); log "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ %s\n' "$*"
    return 0
  fi
  "$@"
}

run_shell() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ %s\n' "$*"
    return 0
  fi
  /bin/sh -c "$*"
}

ask_yes_no() {
  local prompt=$1 answer
  if [ "${DOTFILES_ASSUME_YES:-0}" = "1" ]; then return 0; fi
  if have gum; then
    gum confirm "$prompt"
    return $?
  fi
  printf '%s [y/N] ' "$prompt"
  IFS= read -r answer || true
  case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

choose_mode() {
  if [ -n "$MODE" ]; then return 0; fi
  if have gum; then
    MODE=$(gum choose --header="Choose dotfiles installation mode" safe essential mirror)
  else
    printf '%s\n' "Choose mode: 1) safe  2) essential  3) mirror"
    printf '> '
    local choice
    IFS= read -r choice || true
    case "$choice" in
      2|essential) MODE=essential ;;
      3|mirror) MODE=mirror ;;
      *) MODE=safe ;;
    esac
  fi
}

detect_platform() {
  OS=$(uname -s 2>/dev/null || printf unknown)
  DISTRO=unknown
  WSL=0
  if [ "$OS" = Darwin ]; then
    PLATFORM=macos
  elif [ "$OS" = Linux ]; then
    PLATFORM=linux
    if [ -r /etc/os-release ]; then
      . /etc/os-release
      DISTRO=${ID:-unknown}
    fi
    if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_INTEROP:-}" ]; then
      WSL=1
      DISTRO=wsl
    fi
  else
    PLATFORM=unsupported
  fi
}

package_manager() {
  case "$PLATFORM:$DISTRO" in
    macos:*) have brew && printf brew || printf none ;;
    linux:arch) have pacman && printf pacman || printf none ;;
    linux:*) have apt-get && printf apt || printf none ;;
    *) printf none ;;
  esac
}

sudo_prefix() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then return 0; fi
  if have sudo; then printf 'sudo'; return 0; fi
  return 1
}

bootstrap_brew() {
  [ "$PLATFORM" = macos ] || return 0
  have brew && return 0
  if [ "$MODE" = safe ]; then
    record_skipped "Homebrew is unavailable in safe mode"
    return 1
  fi
  if ! ask_yes_no "Homebrew is missing. Install Homebrew now?"; then
    record_skipped "Homebrew installation declined"
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '+ install Homebrew from the official installer\n'
    return 0
  fi
  if ! have curl; then
    record_failed "Cannot install Homebrew: curl is unavailable"
    return 1
  fi
  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    record_failed "Homebrew installation failed"
    return 1
  fi
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  have brew || record_failed "Homebrew still unavailable after installation"
}

brew_installed() { brew list --formula "$1" >/dev/null 2>&1; }
apt_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
pacman_installed() { pacman -Q "$1" >/dev/null 2>&1; }

install_one() {
  local package=$1 manager=$2 prefix
  case "$manager" in
    brew)
      brew_installed "$package" && { record_skipped "already installed: $package"; return 0; }
      if run brew install "$package"; then record_installed "$package"; else record_failed "brew install failed: $package"; fi
      ;;
    apt)
      apt_installed "$package" && { record_skipped "already installed: $package"; return 0; }
      prefix=$(sudo_prefix) || { record_failed "sudo unavailable for apt package: $package"; return 1; }
      if [ "$prefix" = sudo ]; then run sudo -v || { record_failed "sudo authentication failed"; return 1; }; fi
      if [ "$prefix" = sudo ]; then
        if run sudo apt-get install -y "$package"; then record_installed "$package"; else record_failed "apt install failed: $package"; fi
      elif run apt-get install -y "$package"; then
        record_installed "$package"
      else
        record_failed "apt install failed: $package"
      fi
      ;;
    pacman)
      pacman_installed "$package" && { record_skipped "already installed: $package"; return 0; }
      prefix=$(sudo_prefix) || { record_failed "sudo unavailable for pacman package: $package"; return 1; }
      if [ "$prefix" = sudo ]; then
        if run sudo pacman -S --needed --noconfirm "$package"; then record_installed "$package"; else record_failed "pacman install failed: $package"; fi
      elif run pacman -S --needed --noconfirm "$package"; then
        record_installed "$package"
      else
        record_failed "pacman install failed: $package"
      fi
      ;;
    *) record_skipped "no package manager available for: $package"; ;;
  esac
}

install_packages() {
  [ "$MODE" != safe ] || return 0
  local manager
  manager=$(package_manager)
  if [ "$manager" = none ]; then
    record_skipped "no supported package manager detected for $PLATFORM/$DISTRO"
    return 0
  fi

  if [ "$manager" = brew ]; then
    bootstrap_brew || return 0
  elif [ "$manager" = apt ]; then
    local prefix
    prefix=$(sudo_prefix 2>/dev/null || true)
    if [ -z "$prefix" ]; then record_failed "sudo is required for apt package installation"; return 0; fi
    if [ "$prefix" = sudo ]; then run sudo -v && run sudo apt-get update || record_failed "apt update failed"; else run apt-get update || record_failed "apt update failed"; fi
  fi

  local package
  if [ "$MODE" = essential ]; then
    case "$manager" in
      brew) for package in bash git gum neovim tmux vim zsh; do install_one "$package" "$manager"; done ;;
      pacman) while IFS= read -r package; do [ -n "$package" ] && install_one "$package" "$manager"; done < "$ROOT_DIR/packages/linux/arch.txt" ;;
      apt) while IFS= read -r package; do [ -n "$package" ] && install_one "$package" "$manager"; done < "$ROOT_DIR/packages/linux/ubuntu.txt" ;;
    esac
    return 0
  fi

  case "$manager" in
    brew)
      while IFS= read -r package; do case "$package" in brew\ \"*\"*) package=${package#brew \"}; package=${package%\"}; install_one "$package" brew ;; esac; done < "$ROOT_DIR/packages/macos/Brewfile.curated"
      if [ "$FULL_APPS" -eq 1 ]; then
        while IFS= read -r package; do case "$package" in brew\ \"*\"*) package=${package#brew \"}; package=${package%\"}; install_one "$package" brew ;; esac; done < "$ROOT_DIR/packages/macos/Brewfile.full"
        while IFS= read -r package; do
          case "$package" in cask\ \"*\"*) package=${package#cask \"}; package=${package%\"}; if brew list --cask "$package" >/dev/null 2>&1; then record_skipped "already installed: $package"; elif run brew install --cask "$package"; then record_installed "$package"; else record_failed "brew cask install failed: $package"; fi ;; esac
        done < "$ROOT_DIR/packages/macos/Brewfile.full"
      fi
      ;;
    pacman) while IFS= read -r package; do [ -n "$package" ] && [[ "$package" != \#* ]] && install_one "$package" pacman; done < "$ROOT_DIR/packages/linux/arch.txt" ;;
    apt) while IFS= read -r package; do [ -n "$package" ] && [[ "$package" != \#* ]] && install_one "$package" apt; done < "$ROOT_DIR/packages/linux/ubuntu.txt" ;;
  esac
}

backup_path() {
  local destination=$1 relative
  [ -e "$destination" ] || [ -L "$destination" ] || return 0
  relative=${destination#"$HOME"/}
  local backup="$BACKUP_ROOT/$relative"
  mkdir -p "$(dirname "$backup")"
  mv "$destination" "$backup"
}

copy_file() {
  local source=$1 destination=$2
  if [ "$DRY_RUN" -eq 1 ]; then printf '+ copy %s -> %s\n' "$source" "$destination"; return 0; fi
  backup_path "$destination"
  mkdir -p "$(dirname "$destination")"
  cp -p "$source" "$destination" || { record_failed "copy failed: $destination"; return 1; }
  record_installed "$destination"
}

copy_dir() {
  local source=$1 destination=$2
  if [ "$DRY_RUN" -eq 1 ]; then printf '+ copy directory %s -> %s\n' "$source" "$destination"; return 0; fi
  backup_path "$destination"
  mkdir -p "$(dirname "$destination")"
  cp -R "$source" "$destination" || { record_failed "directory copy failed: $destination"; return 1; }
  record_installed "$destination"
}

deploy_configs() {
  if [ -z "$BACKUP_ROOT" ]; then BACKUP_ROOT="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"; fi
  mkdir -p "$BACKUP_ROOT"
  local file
  for file in .profile .bashrc .bash_profile .zshrc .zprofile .vimrc .tmux.conf; do
    copy_file "$ROOT_DIR/home/$file" "$HOME/$file"
  done
  copy_dir "$ROOT_DIR/home/.config/nvim" "$HOME/.config/nvim"
  copy_file "$ROOT_DIR/home/.config/dotfiles/profile.default" "$HOME/.config/dotfiles/profile"
  if [ "$PLATFORM" = macos ] && [ -d "$ROOT_DIR/home/.config/ghostty" ]; then
    copy_dir "$ROOT_DIR/home/.config/ghostty" "$HOME/.config/ghostty"
  fi
  if [ "$INSTALL_ROOT" -eq 1 ]; then
    local prefix=""
    [ "${EUID:-$(id -u)}" -eq 0 ] || prefix=sudo
    for file in .bashrc .bash_profile .zshrc; do
      if [ "$DRY_RUN" -eq 1 ]; then printf '+ install root/%s\n' "$file"; elif [ "$prefix" = sudo ]; then sudo install -m 0644 "$ROOT_DIR/root/$file" "/var/root/$file"; else install -m 0644 "$ROOT_DIR/root/$file" "/var/root/$file"; fi
    done
  fi
  if [ "$DRY_RUN" -eq 0 ]; then printf '%s\n' "$MODE" > "$HOME/.config/dotfiles/profile"; fi
}

clone_or_update() {
  local url=$1 destination=$2
  if [ -d "$destination/.git" ]; then
    run git -C "$destination" pull --ff-only || record_failed "plugin update failed: $destination"
  elif [ ! -e "$destination" ]; then
    run git clone --depth 1 "$url" "$destination" || record_failed "plugin clone failed: $url"
  else
    record_failed "plugin destination is not a git checkout: $destination"
  fi
}

install_frameworks() {
  [ "$MODE" = mirror ] || return 0
  have git || { record_failed "git is required for mirror framework installation"; return 0; }
  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  local url name
  while IFS= read -r url; do
    [[ -z "$url" || "$url" = \#* ]] && continue
    [[ "$url" = "https://github.com/ohmyzsh/ohmyzsh.git" ]] && continue
    name=${url##*/}; name=${name%.git}
    clone_or_update "$url" "$HOME/.oh-my-zsh/custom/plugins/$name"
  done < "$ROOT_DIR/plugins/oh-my-zsh.txt"
}

install_editor_plugins() {
  [ "$MODE" = mirror ] || return 0
  if ! have curl; then record_failed "curl is required for Vim-Plug"; return 0; fi
  mkdir -p "$HOME/.vim/autoload"
  if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    run curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || record_failed "Vim-Plug installation failed"
  fi
  local lazypath="$HOME/.local/share/nvim/lazy/lazy.nvim"
  if ! have git; then record_failed "git is required for lazy.nvim"; return 0; fi
  clone_or_update https://github.com/folke/lazy.nvim.git "$lazypath"
  if have nvim && [ "$DRY_RUN" -eq 0 ]; then
    nvim --headless -u "$HOME/.config/nvim/init.lua" '+Lazy! sync' +qa >/tmp/dotfiles-nvim-sync.log 2>&1 || record_failed "Neovim plugin synchronization failed; see /tmp/dotfiles-nvim-sync.log"
  fi
}

offer_shell_change() {
  [ "$MODE" = mirror ] || return 0
  have zsh || return 0
  local zsh_path
  zsh_path=$(command -v zsh)
  [ "${SHELL:-}" = "$zsh_path" ] && return 0
  if ask_yes_no "Change the login shell to $zsh_path?"; then
    if [ "$DRY_RUN" -eq 1 ]; then printf '+ chsh -s %s\n' "$zsh_path"; elif have chsh && chsh -s "$zsh_path"; then record_installed "login shell changed to zsh"; else record_failed "could not change login shell"; fi
  fi
}

summary() {
  printf '\n%s\n' '--- dotfiles summary ---'
  printf 'mode: %s platform: %s distro: %s wsl: %s\n' "$MODE" "$PLATFORM" "$DISTRO" "$WSL"
  printf 'installed/actions: %d\n' "${#INSTALLED[@]}"
  printf 'skipped: %d\n' "${#SKIPPED[@]}"
  printf 'failed: %d\n' "${#FAILED[@]}"
  if [ "${#FAILED[@]}" -gt 0 ]; then printf '%s\n' "${FAILED[@]}"; fi
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --mode) MODE=${2:?missing mode}; shift 2 ;;
      --mode=*) MODE=${1#*=}; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --install-root) INSTALL_ROOT=1; shift ;;
      --help|-h) usage; return 0 ;;
      *) usage >&2; return 1 ;;
    esac
  done
  case "$MODE" in ""|safe|essential|mirror) ;; *) error "invalid mode: $MODE"; return 1 ;; esac
  choose_mode
  detect_platform
  [ "$PLATFORM" != unsupported ] || { error "unsupported operating system: $OS"; return 1; }

  if [ "$MODE" != safe ]; then
    log "platform=$PLATFORM distro=$DISTRO wsl=$WSL mode=$MODE"
    if [ "$MODE" = mirror ] && [ "$PLATFORM" = macos ] && ask_yes_no "Install the full macOS application manifest too?"; then FULL_APPS=1; fi
    ask_yes_no "Proceed with package and configuration installation?" || { log "installation cancelled"; return 0; }
    bootstrap_brew || true
  fi

  install_packages
  deploy_configs
  install_frameworks
  install_editor_plugins
  offer_shell_change
  summary
  [ "${#FAILED[@]}" -eq 0 ] && return 0 || return 2
}

main "$@"
