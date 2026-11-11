local M = {}

function M.setup()
  -- Handle clicks and wheel scrolling inside Neovim.
  vim.opt.mouse = "a"
  -- OSC 52 writes to the clipboard of the client currently attached to tmux,
  -- whether that client is local or connected over SSH.
  if vim.env.TMUX and vim.env.TMUX ~= "" then
    vim.g.clipboard = "osc52"
  end
  vim.keymap.set("x", "<S-F1>", '"+y', { silent = true, desc = "Copy selection to client clipboard" })
  vim.keymap.set("x", "<S-F2>", '"+d', { silent = true, desc = "Cut selection to client clipboard" })
end

return M
