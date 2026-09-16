vim.cmd("highlight clear")
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "ghostblack"

local c = {
  bg = "#000000", fg = "#ffffff", muted = "#808080", blue = "#75beff",
  cyan = "#4ec9b0", green = "#6a9955", yellow = "#ffff00", orange = "#ce9178",
  red = "#f44747", magenta = "#c586c0", select = "#264f78",
}
local function hi(group, opts) vim.api.nvim_set_hl(0, group, opts) end

hi("Normal", { fg = c.fg, bg = c.bg })
hi("NormalNC", { fg = c.fg, bg = c.bg })
hi("EndOfBuffer", { fg = c.bg, bg = c.bg })
hi("LineNr", { fg = c.blue, bg = c.bg })
hi("CursorLineNr", { fg = c.yellow, bg = c.bg, bold = true })
hi("SignColumn", { fg = c.blue, bg = c.bg })
hi("StatusLine", { fg = c.fg, bg = c.bg })
hi("StatusLineNC", { fg = c.fg, bg = c.bg })
hi("StatusLineMode", { fg = c.yellow, bg = c.bg, bold = true })
hi("Visual", { bg = c.select })
hi("Search", { fg = c.bg, bg = c.yellow })
hi("Pmenu", { fg = c.fg, bg = "#0b0b0b" })
hi("PmenuSel", { fg = c.fg, bg = "#094771" })
hi("Comment", { fg = c.green, italic = true })
hi("String", { fg = c.orange })
hi("Function", { fg = c.yellow })
hi("Keyword", { fg = c.magenta })
hi("Type", { fg = c.cyan })
hi("Constant", { fg = c.blue })
hi("Number", { fg = "#b5cea8" })
hi("Directory", { fg = c.blue, bold = true })
hi("DashboardHeader", { fg = c.fg })
hi("DashboardSection", { fg = c.yellow, bold = true })
hi("DashboardItem", { fg = c.fg })
hi("DashboardFooter", { fg = c.yellow, bold = true })
