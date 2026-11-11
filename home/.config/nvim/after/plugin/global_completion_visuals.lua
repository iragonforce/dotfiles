-- Purpose: consistent completion icons, match highlighting and
-- dropdown appearance for all languages using nvim-cmp.
-- Input: existing LSP, buffer, path and snippet completion sources.
-- Output: Nerd Font icons and highlighted matching characters.
-- Does not alter completion sources, mappings, signatures or Nvlime.

local icons = {
  Text = "",
  Method = "",
  Function = "",
  Constructor = "",
  Field = "",
  Variable = "",
  Class = "",
  Interface = "",
  Module = "",
  Property = "",
  Unit = "",
  Value = "",
  Enum = "",
  Keyword = "",
  Snippet = "",
  Color = "",
  File = "",
  Reference = "",
  Folder = "",
  EnumMember = "",
  Constant = "",
  Struct = "",
  Event = "",
  Operator = "",
  TypeParameter = "",
}

local function apply_colors()
  local groups = {
    CmpItemAbbr = { fg = "#e6e6e9" },
    CmpItemAbbrMatch = { fg = "#59aaff", bold = true },
    CmpItemAbbrMatchFuzzy = { fg = "#59aaff", bold = true },

    CmpItemKindText = { fg = "#e6e6e9" },
    CmpItemKindFunction = { fg = "#91e500" },
    CmpItemKindMethod = { fg = "#91e500" },
    CmpItemKindConstructor = { fg = "#91e500" },
    CmpItemKindVariable = { fg = "#59aaff" },
    CmpItemKindField = { fg = "#00d6ae" },
    CmpItemKindProperty = { fg = "#00d6ae" },
    CmpItemKindClass = { fg = "#d98aff" },
    CmpItemKindInterface = { fg = "#d98aff" },
    CmpItemKindStruct = { fg = "#d98aff" },
    CmpItemKindModule = { fg = "#d98aff" },
    CmpItemKindKeyword = { fg = "#ff136b" },
    CmpItemKindConstant = { fg = "#ffb400" },
    CmpItemKindEnum = { fg = "#ffb400" },
    CmpItemKindEnumMember = { fg = "#ffb400" },
    CmpItemKindSnippet = { fg = "#f0cc79" },
    CmpItemKindFile = { fg = "#59aaff" },
    CmpItemKindFolder = { fg = "#59aaff" },
  }

  for name, options in pairs(groups) do
    vim.api.nvim_set_hl(0, name, options)
  end
end

local installed = false

local function configure_cmp()
  if installed then return end

  local ok, cmp = pcall(require, "cmp")
  if not ok then return end

  -- Merge into the existing global configuration.
  -- Buffer-local Lisp formatting continues to take precedence.
  cmp.setup({
    formatting = {
      fields = { "kind", "abbr" },
      format = function(_, item)
        local kind = item.kind or "Text"
        item.kind = icons[kind] or ""
        item.menu = ""
        return item
      end,
    },
    view = {
      entries = {
        name = "custom",
        vertical_positioning = "below",
        selection_order = "top_down",
      },
    },
  })

  installed = true
end

apply_colors()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup(
    "GlobalCompletionColors",
    { clear = true }
  ),
  callback = function()
    vim.schedule(apply_colors)
  end,
})

-- Apply after lazy-loaded nvim-cmp finishes initializing.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup(
    "GlobalCompletionSetup",
    { clear = true }
  ),
  pattern = "CmpReady",
  callback = function()
    vim.schedule(configure_cmp)
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  callback = function()
    vim.schedule(configure_cmp)
  end,
})

vim.schedule(configure_cmp)
