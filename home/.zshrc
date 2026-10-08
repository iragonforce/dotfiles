# =============================================================================
# Zsh configuration copied from Qubit and adapted for tensor
# =============================================================================

# Local command paths
export PATH="$HOME/bin:$PATH"

# =============================================================================
# OH-MY-ZSH CONFIGURATION
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="risto"

# =============================================================================
# ZSH HISTORY CONFIGURATION (Increased)
# =============================================================================

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS       # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS      # Do not display a line previously found
setopt HIST_IGNORE_SPACE      # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS       # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks before recording entry
setopt HIST_VERIFY             # Show command with history expansion before running it
setopt APPEND_HISTORY          # Append to history file, don't overwrite it
setopt INC_APPEND_HISTORY      # Write to the history file immediately, not when the shell exits

# =============================================================================
# ZSH PLUGINS
# =============================================================================

# Core plugins
plugins=(
    # Oh-My-Zsh built-in plugins
    git
    colored-man-pages
    command-not-found
    extract
    safe-paste
    web-search

    # Development tools
    npm
    yarn
    kubectl
    docker
    pipenv
    pip
    python
)

# =============================================================================
# CUSTOM PLUGINS (External)
# =============================================================================

# zsh-autosuggestions
if [ -f ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#9aa3ad"
fi

# history-substring-search
if [ -f ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source ~/.oh-my-zsh/custom/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey -M vicmd 'k' history-substring-search-up
    bindkey -M vicmd 'j' history-substring-search-down
fi

# you-should-use
if [ -f ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh ]; then
    source ~/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh
fi

# autojump
if [ -f /usr/share/autojump/autojump.sh ]; then
    source /usr/share/autojump/autojump.sh
fi

# zsh-z (alternative to autojump)
if [ -f ~/.oh-my-zsh/custom/plugins/zsh-z/zsh-z.plugin.zsh ]; then
    source ~/.oh-my-zsh/custom/plugins/zsh-z/zsh-z.plugin.zsh
fi

# fzf
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# autoenv
if [ -f ~/.oh-my-zsh/custom/plugins/autoenv/autoenv.plugin.zsh ]; then
    source ~/.oh-my-zsh/custom/plugins/autoenv/autoenv.plugin.zsh
fi

# =============================================================================
# LOAD OH-MY-ZSH
# =============================================================================

source "$ZSH/oh-my-zsh.sh"

# Ensure SSH sessions always stay in insert/emacs mode.
if [[ -n "${SSH_CONNECTION:-}" ]]; then
    bindkey -e
    function zle-line-init() { zle -K emacs; }
    function zle-keymap-select() { zle -K emacs; }
    zle -N zle-line-init
    zle -N zle-keymap-select
fi

# =============================================================================
# ALIASES
# =============================================================================

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dexec='docker exec -it'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kd='kubectl describe'

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
# CUSTOM FUNCTIONS
# =============================================================================

# Quick directory navigation
function take() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"   ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# =============================================================================
# END OF CONFIGURATION
# =============================================================================

# Load local environment if it exists (e.g. from uv)
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi



# Qubit prompt colours adapted to the Ghostty palette.
ZSH_THEME_GIT_PROMPT_PREFIX="%F{red}git:("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%f"
PROMPT='%(?:%F{green}➜ :%F{red}➜ ) %F{yellow}%n%f@%F{blue}%m%f  %F{14}%~%f  $(git_prompt_info)%F{white}'

# Tensor: match the Qubit prompt and terminal palette, then keep local tmux workflow.
export COLORTERM=truecolor
unset NO_COLOR
if [ -f ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
if (( ${+ZSH_HIGHLIGHT_STYLES} )); then
  ZSH_HIGHLIGHT_STYLES[command]='fg=#7ad99a,bold'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7ad99a,bold'
  ZSH_HIGHLIGHT_STYLES[function]='fg=#7ad99a,bold'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#7ad99a,bold'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff6b6b,bold'
  ZSH_HIGHLIGHT_STYLES[path]='fg=#dce3e8'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f4ce73'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f4ce73'
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9aa3ad'

zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -g __codex_cmd_start=0
typeset -g __codex_cmd_name=""

__codex_excluded_commands=(
    vim
    nvim
    vi
    ssh
    ping
)

__codex_extract_command_name() {
    local cmd="${1#"${1%%[![:space:]]*}"}"
    local -a words
    words=(${(z)cmd})

    local word
    for word in "${words[@]}"; do
        case "$word" in
            sudo|command|builtin|noglob|nocorrect|env|time)
                continue
                ;;
            *=*)
                continue
                ;;
            *)
                print -r -- "$word"
                return 0
                ;;
        esac
    done

    return 1
}

__codex_preexec() {
    __codex_cmd_start=$EPOCHREALTIME
    __codex_cmd_name="$(__codex_extract_command_name "$1")"
}

__codex_precmd() {
    local exit_code=$?

    [[ $__codex_cmd_start == 0 ]] && return

    local start_time=$__codex_cmd_start
    local cmd_name="$__codex_cmd_name"
    __codex_cmd_start=0
    __codex_cmd_name=""

    local elapsed_ms=$(( (EPOCHREALTIME - start_time) * 1000.0 ))
    local elapsed_ms_fmt
    printf -v elapsed_ms_fmt '%.2f ms' "$elapsed_ms"

    if [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux set-option -gq @last_cmd_ms "${elapsed_ms_fmt}" 2>/dev/null || true
    fi

    (( ${#__codex_excluded_commands[(I)$cmd_name]} )) && return

    local symbol color

    if (( exit_code == 0 )); then
        symbol="✓"
        color="green"
    else
        symbol="✗"
        color="red"
    fi

    print -P "%F{$color}${symbol}%f %F{242}• ${elapsed_ms_fmt}%f"
}

add-zsh-hook preexec __codex_preexec
add-zsh-hook precmd __codex_precmd

export EDITOR="$HOME/.local/bin/tmux-managed-nvim"
export VISUAL="$EDITOR"

if [[ -o interactive ]] && [[ "$(uname -s)" == "Linux" ]] && [[ -z "${SSH_CONNECTION:-}" ]] && [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]] && [[ "${XDG_VTNR:-}" == "1" ]]; then
  exec start-hyprland
fi

if [[ -o interactive && -n "${TMUX:-}" ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi

if [[ -o interactive ]]; then
  export TMUX_REAL_NVIM_BIN="${TMUX_REAL_NVIM_BIN:-$(whence -p nvim 2>/dev/null)}"

  nvim() {
    "$HOME/.local/bin/tmux-managed-nvim" "$@"
  }

  vim() {
    nvim "$@"
  }

  vi() {
    nvim "$@"
  }

  ssh() {
    "$HOME/.local/bin/tmux-ssh" "$@"
  }

  if command -v tmux >/dev/null 2>&1; then
    if [[ -n "${TMUX_LOGIN_BOOTSTRAPPED:-}" ]]; then
      unset TMUX_LOGIN_BOOTSTRAPPED
    else
      "$HOME/.local/bin/tmux-auto-start"
    fi

    if [[ -n "${TMUX_AUTO_EXIT_ON_DETACH:-}" && -z "${TMUX:-}" ]]; then
      exit
    fi
  fi
fi
