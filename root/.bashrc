export TERM="${TERM:-xterm-256color}"

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
  local git_segment
  [ "$last_status" -ne 0 ] && arrow_color='0;31'
  git_segment=$(__dotfiles_git_prompt)
  PS1="\\[\\e[${arrow_color}m\\]➜\\[\\e[0m\\] \\[\e[0;31m\\]\\u\\[\\e[0m\\]@\\[\\e[0;33m\\]\\h\\[\\e[0m\\]"
  if [ -n "$git_segment" ]; then
    PS1+="\\[\\e[0;31m\\]${git_segment}\\[\\e[0m\\]"
  fi
  PS1+=" \\[\\e[0;97m\\]\\w\\[\\e[0m\\] "
}

PROMPT_COMMAND=__dotfiles_set_prompt
__dotfiles_set_prompt
