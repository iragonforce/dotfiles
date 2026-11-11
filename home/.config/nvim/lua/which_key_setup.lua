-- Purpose: display existing Neovim shortcuts using Which-key.
-- Input: Leader key in Normal or Visual mode.
-- Output: modern shortcut-discovery popup.
-- Does not override existing mappings or the motions-help plugin.

local M = {}

function M.setup()
  local wk = require("which-key")

  wk.setup({
    preset = "modern",
    delay = 300,

    win = {
      border = "rounded",
    },

    triggers = {
      { "<leader>", mode = { "n", "v" } },
    },
  })

  wk.add({
    { "<leader>g", group = "Git" },
    { "<leader>c", group = "Code" },
    { "<leader>l", group = "LSP" },
    { "<leader>b", group = "Buffers" },
    { "<leader>r", group = "REPL" },
  })
end

return M
