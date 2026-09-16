# Portable Zsh configuration. Oh My Zsh and custom plugins are optional.
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

if [ -r "$HOME/.config/dotfiles/profile" ]; then
  DOTFILES_PROFILE=$(cat "$HOME/.config/dotfiles/profile")
fi
export DOTFILES_PROFILE=${DOTFILES_PROFILE:-safe}

if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

case ":${PATH:-}:" in
  *:"$HOME/.local/bin":*) ;;
  *) PATH="$HOME/.local/bin:${PATH:-}" ;;
esac
case ":${PATH:-}:" in
  *:"$HOME/bin":*) ;;
  *) PATH="$HOME/bin:${PATH:-}" ;;
esac
export PATH

if [ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME=""
  plugins=(git colored-man-pages command-not-found extract safe-paste)
  source "$ZSH/oh-my-zsh.sh"
fi

for plugin in \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  [ -r "$plugin" ] && source "$plugin"
done

HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
HISTSIZE=100000
SAVEHIST=100000
setopt append_history inc_append_history share_history hist_ignore_dups
setopt prompt_subst

__dotfiles_git_prompt() {
  local branch dirty
  branch=$(command git symbolic-ref --short HEAD 2>/dev/null \
    || command git describe --tags --exact-match HEAD 2>/dev/null \
    || command git rev-parse --short HEAD 2>/dev/null) || return 0
  dirty=''
  [[ -n "$(command git status --porcelain 2>/dev/null)" ]] && dirty='*'
  print -r -- " git:(${branch}${dirty})"
}

if (( EUID == 0 )); then
  PROMPT='%(?:%F{green}➜%f:%F{red}➜%f) %F{red}%n%f@%F{yellow}%m%f%F{red}$( __dotfiles_git_prompt )%f %F{15}%~%f '
else
  PROMPT='%(?:%F{green}➜%f:%F{red}➜%f) %F{yellow}%n%f@%F{blue}%m%f%F{red}$( __dotfiles_git_prompt )%f %F{15}%~%f '
fi

if command -v fastfetch >/dev/null 2>&1 && [[ -o interactive ]]; then
  fastfetch
fi

export EDITOR="${EDITOR:-$(whence -p nvim 2>/dev/null || whence -p vim 2>/dev/null)}"
export VISUAL="${VISUAL:-$EDITOR}"
alias py='python3'
