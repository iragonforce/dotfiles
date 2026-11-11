-- Ghostblack semantic highlighting.
-- Purpose: apply one consistent palette with language-specific distinctions.
-- Input: Tree-sitter captures and optional LSP semantic-token groups.
-- Output: foreground/style highlights only; never changes backgrounds.

local M = {}

local p = {
  pink   = "#ff136b",
  green  = "#91e500",
  blue   = "#59aaff",
  cyan   = "#00d6ae",
  purple = "#d98aff",
  orange = "#ffb400",
  yellow = "#f0cc79",
  white  = "#e6e6e9",
  muted  = "#85858e",
}

local base = {
  ["@variable"] = p.white,
  ["@variable.parameter"] = p.blue,
  ["@variable.builtin"] = p.yellow,
  ["@variable.member"] = p.cyan,
  ["@property"] = p.cyan,

  ["@function"] = p.green,
  ["@function.call"] = p.yellow,
  ["@function.method"] = p.green,
  ["@function.method.call"] = p.yellow,
  ["@function.builtin"] = p.yellow,
  ["@constructor"] = p.green,

  ["@type"] = p.purple,
  ["@type.builtin"] = p.purple,
  ["@type.definition"] = p.purple,
  ["@attribute"] = p.purple,
  ["@module"] = p.purple,

  ["@keyword"] = p.pink,
  ["@keyword.function"] = p.pink,
  ["@keyword.return"] = p.pink,
  ["@keyword.conditional"] = p.pink,
  ["@keyword.repeat"] = p.pink,
  ["@keyword.import"] = p.pink,
  ["@keyword.operator"] = p.pink,
  ["@keyword.directive"] = p.pink,

  ["@constant"] = p.orange,
  ["@constant.builtin"] = p.orange,
  ["@constant.macro"] = p.orange,
  ["@number"] = p.purple,
  ["@number.float"] = p.purple,
  ["@boolean"] = p.orange,

  ["@string"] = p.yellow,
  ["@string.escape"] = p.cyan,
  ["@string.special"] = p.cyan,
  ["@comment"] = { fg = p.muted, italic = true },

  ["@operator"] = p.white,
  ["@punctuation.bracket"] = p.white,
  ["@punctuation.delimiter"] = p.muted,

  ["@tag"] = p.pink,
  ["@tag.attribute"] = p.cyan,
  ["@tag.delimiter"] = p.muted,

  ["@markup.heading"] = { fg = p.pink, bold = true },
  ["@markup.strong"] = { fg = p.orange, bold = true },
  ["@markup.italic"] = { fg = p.purple, italic = true },
  ["@markup.link"] = p.blue,
  ["@markup.link.url"] = p.cyan,
  ["@markup.raw"] = p.yellow,
  ["@markup.list"] = p.orange,
}

local lsp = {
  ["@lsp.type.variable"] = p.white,
  ["@lsp.type.parameter"] = p.blue,
  ["@lsp.type.property"] = p.cyan,
  ["@lsp.type.function"] = p.yellow,
  ["@lsp.type.method"] = p.yellow,
  ["@lsp.type.type"] = p.purple,
  ["@lsp.type.class"] = p.purple,
  ["@lsp.type.struct"] = p.purple,
  ["@lsp.type.interface"] = p.purple,
  ["@lsp.type.enum"] = p.purple,
  ["@lsp.type.typeParameter"] = p.purple,
  ["@lsp.type.namespace"] = p.purple,
  ["@lsp.type.keyword"] = p.pink,
  ["@lsp.type.macro"] = p.orange,
  ["@lsp.type.enumMember"] = p.orange,
  ["@lsp.type.decorator"] = p.purple,

  ["@lsp.typemod.function.definition"] = p.green,
  ["@lsp.typemod.function.declaration"] = p.green,
  ["@lsp.typemod.method.definition"] = p.green,
  ["@lsp.typemod.method.declaration"] = p.green,
}

-- Language-specific overrides. Keys are Tree-sitter capture names.
local languages = {
  python = {
    ["@type"] = p.green,
    ["@function"] = p.green,
    ["@function.builtin"] = p.yellow,
    ["@variable.parameter"] = p.blue,
    ["@variable.member"] = p.cyan,
    ["@attribute"] = p.purple,
    ["@decorator"] = p.purple,
  },

  c = {
    ["@function"] = p.green,
    ["@type.builtin"] = p.cyan,
    ["@constant.macro"] = p.orange,
    ["@keyword.directive"] = p.pink,
    ["@variable.parameter"] = p.blue,
    ["@variable.member"] = p.cyan,
  },

  cpp = {
    ["@function"] = p.green,
    ["@type.builtin"] = p.cyan,
    ["@module"] = p.purple,
    ["@type"] = p.purple,
    ["@type.parameter"] = p.purple,
    ["@constant.macro"] = p.orange,
    ["@variable.member"] = p.cyan,
  },

  java = {
    ["@function.method"] = p.green,
    ["@type"] = p.purple,
    ["@attribute"] = p.pink,
    ["@variable.member"] = p.cyan,
    ["@constant"] = p.orange,
  },

  javascript = {
    ["@function"] = p.green,
    ["@function.call"] = p.yellow,
    ["@variable.parameter"] = p.blue,
    ["@property"] = p.cyan,
    ["@module"] = p.purple,
    ["@variable.builtin"] = p.yellow,
  },

  typescript = {
    ["@function"] = p.green,
    ["@type"] = p.purple,
    ["@type.definition"] = p.purple,
    ["@type.parameter"] = p.purple,
    ["@property"] = p.cyan,
    ["@variable.parameter"] = p.blue,
  },

  tsx = {
    ["@tag"] = p.pink,
    ["@tag.attribute"] = p.cyan,
    ["@type"] = p.purple,
    ["@function"] = p.green,
    ["@property"] = p.cyan,
  },

  html = {
    ["@tag"] = p.pink,
    ["@tag.attribute"] = p.cyan,
    ["@string"] = p.yellow,
    ["@tag.delimiter"] = p.muted,
  },

  markdown = {
    ["@markup.heading.1"] = { fg = p.pink, bold = true },
    ["@markup.heading.2"] = { fg = p.orange, bold = true },
    ["@markup.heading.3"] = { fg = p.green, bold = true },
    ["@markup.heading.4"] = { fg = p.blue, bold = true },
    ["@markup.heading.5"] = { fg = p.purple, bold = true },
    ["@markup.heading.6"] = { fg = p.cyan, bold = true },
    ["@markup.link"] = p.blue,
    ["@markup.raw"] = p.yellow,
  },

  markdown_inline = {
    ["@markup.strong"] = { fg = p.orange, bold = true },
    ["@markup.italic"] = { fg = p.purple, italic = true },
    ["@markup.link"] = p.blue,
    ["@markup.link.url"] = p.cyan,
    ["@markup.raw"] = p.yellow,
  },

  commonlisp = {
    ["@function"] = p.green,
    ["@function.macro"] = p.orange,
    ["@keyword"] = p.pink,
    ["@symbol"] = p.white,
    ["@type"] = p.purple,
  },

  haskell = {
    ["@function"] = p.green,
    ["@constructor"] = p.green,
    ["@type"] = p.purple,
    ["@type.parameter"] = p.blue,
    ["@operator"] = p.pink,
  },

  yaml = {
    ["@property"] = p.cyan,
    ["@string"] = p.yellow,
    ["@number"] = p.orange,
    ["@boolean"] = p.pink,
    ["@constant.builtin"] = p.pink,
    ["@label"] = p.purple,
  },

  lua = {
    ["@function"] = p.green,
    ["@function.call"] = p.yellow,
    ["@variable.parameter"] = p.blue,
    ["@variable.builtin"] = p.yellow,
    ["@property"] = p.cyan,
    ["@type"] = p.purple,
  },

  bash = {
    ["@function"] = p.green,
    ["@function.call"] = p.green,
    ["@variable"] = p.blue,
    ["@string"] = p.yellow,
    ["@string.special"] = p.cyan,
    ["@keyword"] = p.pink,
  },

  swift = {
    ["@function"] = p.green,
    ["@type"] = p.purple,
    ["@attribute"] = p.pink,
    ["@property"] = p.cyan,
    ["@variable.parameter"] = p.blue,
  },

  csv = {
    ["@property"] = p.cyan,
    ["@number"] = p.orange,
    ["@string"] = p.yellow,
  },
}

local language_lsp = {
  python = {
    ["@lsp.type.class"] = p.green,
    ["@lsp.type.decorator"] = p.purple,
  },
  c = {
    ["@lsp.type.type"] = p.purple,
    ["@lsp.type.macro"] = p.orange,
  },
  cpp = {
    ["@lsp.type.class"] = p.purple,
    ["@lsp.type.namespace"] = p.purple,
    ["@lsp.type.enumMember"] = p.orange,
  },
  java = {
    ["@lsp.type.class"] = p.purple,
    ["@lsp.type.interface"] = p.purple,
    ["@lsp.type.enumMember"] = p.orange,
  },
  javascript = {
    ["@lsp.type.property"] = p.cyan,
    ["@lsp.type.class"] = p.purple,
  },
  typescript = {
    ["@lsp.type.interface"] = p.purple,
    ["@lsp.type.typeParameter"] = p.purple,
  },
  lua = {
    ["@lsp.type.property"] = p.cyan,
    ["@lsp.type.parameter"] = p.blue,
  },
}

local function apply_groups(groups, suffix)
  suffix = suffix or ""

  for group, color in pairs(groups) do
    local opts = type(color) == "table"
      and vim.deepcopy(color)
      or { fg = color }

    vim.api.nvim_set_hl(0, group .. suffix, opts)
  end
end

function M.apply()
  apply_groups(base)
  apply_groups(lsp)

  for lang, groups in pairs(languages) do
    apply_groups(groups, "." .. lang)
  end

  for lang, groups in pairs(language_lsp) do
    apply_groups(groups, "." .. lang)
  end
end

function M.setup()
  M.apply()

  local group = vim.api.nvim_create_augroup(
    "GhostblackSemanticPalette",
    { clear = true }
  )

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      vim.schedule(M.apply)
    end,
  })
end

return M
