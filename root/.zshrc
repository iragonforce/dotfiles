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

PROMPT='%(?:%F{green}➜%f:%F{red}➜%f) %F{red}%n%f@%F{yellow}%m%f%F{red}$( __dotfiles_git_prompt )%f %F{15}%~%f '
