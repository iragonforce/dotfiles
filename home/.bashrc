# Portable Bash configuration. It is safe when copied without any packages.
export TERM="${TERM:-xterm-256color}"
export BASH_SILENCE_DEPRECATION_WARNING=1

if [ -r "$HOME/.config/dotfiles/profile" ]; then
  DOTFILES_PROFILE=$(cat "$HOME/.config/dotfiles/profile")
fi
export DOTFILES_PROFILE=${DOTFILES_PROFILE:-safe}

if [ -r "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi

__dotfiles_git_prompt() {
  local branch dirty
  branch=$(git symbolic-ref --short HEAD 2>/dev/null \
    || git describe --tags --exact-match HEAD 2>/dev/null \
    || git rev-parse --short HEAD 2>/dev/null) || return 0
  dirty=''
  [ -n "$(git status --porcelain 2>/dev/null)" ] && dirty='*'
  printf ' git:(%s%s)' "$branch" "$dirty"
}

__dotfiles_set_prompt() {
  local last_status=$?
  local arrow_color='0;32'
  local user_color='0;33'
  local host_color='0;34'
  local git_segment

  [ "$last_status" -ne 0 ] && arrow_color='0;31'
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    user_color='0;31'
    host_color='0;33'
  fi

  git_segment=$(__dotfiles_git_prompt)
  PS1="\\[\\e[${arrow_color}m\\]➜\\[\\e[0m\\] \\[\e[${user_color}m\\]\\u\\[\\e[0m\\]@\\[\\e[${host_color}m\\]\\h\\[\\e[0m\\]"
  if [ -n "$git_segment" ]; then
    PS1+="\\[\\e[0;31m\\]${git_segment}\\[\\e[0m\\]"
  fi
  PS1+=" \\[\\e[0;97m\\]\\w\\[\\e[0m\\] "
}

PROMPT_COMMAND=__dotfiles_set_prompt
__dotfiles_set_prompt
