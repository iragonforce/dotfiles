-- Purpose: read-only-by-default Git integration for Neovim.
-- Input: Git-tracked files and their working-tree changes.
-- Output: gutter signs, change previews, navigation and blame.
-- No automatic stage, reset, commit or push operations.

local M = {}

local function apply_colors()
  local highlights = {
    GitSignsAdd = "#91e500",
    GitSignsChange = "#59aaff",
    GitSignsDelete = "#ff136b",
    GitSignsTopdelete = "#ff136b",
    GitSignsChangedelete = "#ffb400",
    GitSignsUntracked = "#91e500",
  }

  for group, color in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, { fg = color })
  end
end

function M.setup()
  local gs = require("gitsigns")

  apply_colors()

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup(
      "GhostblackGitSigns", { clear = true }
    ),
    callback = function()
      vim.schedule(apply_colors)
    end,
  })

  gs.setup({
    signs = {
      add = { text = "┃" },
      change = { text = "┃" },
      delete = { text = "▁" },
      topdelete = { text = "▔" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },

    signcolumn = true,
    signs_staged_enable = true,
    current_line_blame = false,
    attach_to_untracked = false,

    on_attach = function(bufnr)
      local function map(lhs, action, description)
        -- Do not replace existing global or buffer-local mappings.
        local existing = vim.api.nvim_buf_call(bufnr, function()
          return vim.fn.maparg(lhs, "n")
        end)

        if existing ~= "" then
          return
        end

        vim.keymap.set("n", lhs, action, {
          buffer = bufnr,
          silent = true,
          desc = description,
        })
      end

      map("]h", function()
        gs.nav_hunk("next")
      end, "Git: next change")

      map("[h", function()
        gs.nav_hunk("prev")
      end, "Git: previous change")

      map("<leader>gp", function()
        gs.preview_hunk()
      end, "Git: preview change")

      map("<leader>gb", function()
        gs.blame_line({ full = true })
      end, "Git: blame current line")

      map("<leader>gB", function()
        gs.toggle_current_line_blame()
      end, "Git: toggle inline blame")

      map("<leader>gd", function()
        gs.diffthis()
      end, "Git: diff current file")
    end,
  })
end

return M
