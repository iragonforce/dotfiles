# Tensor terminal configuration

This overlay records the Neovim, tmux, zsh, and Ghostty configuration used on
Tensor. Neovim, tmux, and Ghostty came from a previously verified Qubit copy;
zsh was adapted from the older Qubit dotfiles checkout. The overlay is kept
separate from the portable `home/` files and is not installed by `install.sh`.

The Neovim directory includes its local Lua modules, colour scheme, and plugin
lockfile. The Ghostty directory includes the two shaders referenced by its
config and their licence. The zsh config retains Tensor's local tmux and editor
helpers, so it is intended for Tensor or a machine with those helpers installed.

To apply the overlay on Tensor, back up the current files, then copy `.zshrc`
and `.tmux.conf` to `$HOME` and copy `.config/nvim` and `.config/ghostty` to
`$HOME/.config`. New terminal and shell sessions load the copied settings.
