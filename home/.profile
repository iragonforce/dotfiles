if [ -r "$HOME/.config/dotfiles/profile" ]; then
  DOTFILES_PROFILE=$(cat "$HOME/.config/dotfiles/profile")
fi
export DOTFILES_PROFILE=${DOTFILES_PROFILE:-safe}

case ":${PATH:-}:" in
  *:"$HOME/.local/bin":*) ;;
  *) PATH="$HOME/.local/bin:${PATH:-}" ;;
esac
case ":${PATH:-}:" in
  *:"$HOME/bin":*) ;;
  *) PATH="$HOME/bin:${PATH:-}" ;;
esac
export PATH
