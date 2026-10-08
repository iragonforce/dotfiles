vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "ghostblack"
vim.o.termguicolors = true
vim.o.background = "dark"

local c = {
  bg          = "#000000",
  bg_alt      = "#0b0b0b",
  bg_sel      = "#09395a",
  bg_vis      = "#264f78",
  fg          = "#ffffff",
  fg_muted    = "#808080",
  fg_subtle   = "#a0a0a0",
  blue        = "#2991d9",
  blue_soft   = "#75beff",
  blue_dim    = "#569cd6",
  cyan        = "#4ec9b0",
  green       = "#6a9955",
  yellow      = "#ffff00",
  orange      = "#ce9178",
  red         = "#f44747",
  pinkred     = "#c586c0",
  magenta     = "#c586c0",
  white       = "#ffffff",
  black       = "#000000",
  tree_sel    = "#37373d",
  tree_bg     = "#000000",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

hi("Normal",          { fg = c.fg, bg = c.bg })
hi("NormalNC",        { fg = c.fg, bg = c.bg })
hi("EndOfBuffer",     { fg = c.bg, bg = c.bg })
hi("CursorLine",      { bg = c.bg_alt })
hi("CursorColumn",    { bg = c.bg_alt })
hi("ColorColumn",     { bg = c.bg_alt })
hi("LineNr",          { fg = c.blue_soft, bg = c.bg })
hi("CursorLineNr",    { fg = c.blue, bg = c.bg, bold = true })
hi("SignColumn",      { fg = c.blue_soft, bg = c.bg })
hi("FoldColumn",      { fg = c.blue_soft, bg = c.bg })
hi("VertSplit",       { fg = "#101010", bg = c.bg })
hi("WinSeparator",    { fg = "#101010", bg = c.bg })

hi("StatusLine",      { fg = c.white, bg = c.bg })
hi("StatusLineNC",    { fg = c.white, bg = c.bg })
hi("StatusLineMode",  { fg = c.yellow, bg = c.bg, bold = true })
hi("TabLine",         { fg = c.fg_muted, bg = c.bg })
hi("TabLineSel",      { fg = c.blue_soft, bg = c.bg, bold = true })
hi("TabLineFill",     { bg = c.bg })

hi("Visual",          { bg = c.bg_vis })
hi("Search",          { fg = c.black, bg = c.yellow })
hi("IncSearch",       { fg = c.black, bg = c.blue_soft })
hi("MatchParen",      { fg = c.white, bg = "#3a3d41", bold = true })

hi("Pmenu",           { fg = c.fg, bg = c.bg_alt })
hi("PmenuSel",        { fg = c.white, bg = "#094771" })
hi("PmenuSbar",       { bg = "#1e1e1e" })
hi("PmenuThumb",      { bg = "#3e3e42" })
hi("NormalFloat",     { fg = c.fg, bg = c.bg })
hi("FloatBorder",     { fg = "#3e3e42", bg = c.bg })

hi("Comment",         { fg = c.green, italic = true })
hi("Constant",        { fg = c.blue_dim })
hi("String",          { fg = c.orange })
hi("Character",       { fg = c.orange })
hi("Number",          { fg = "#b5cea8" })
hi("Boolean",         { fg = c.blue_dim })
hi("Float",           { fg = "#b5cea8" })
hi("Identifier",      { fg = "#9cdcfe" })
hi("Function",        { fg = c.yellow })
hi("Statement",       { fg = c.pinkred })
hi("Conditional",     { fg = c.pinkred })
hi("Repeat",          { fg = c.pinkred })
hi("Label",           { fg = c.blue_dim })
hi("Operator",        { fg = c.fg })
hi("Keyword",         { fg = c.pinkred })
hi("Exception",       { fg = c.pinkred })
hi("PreProc",         { fg = c.pinkred })
hi("Include",         { fg = c.pinkred })
hi("Define",          { fg = c.pinkred })
hi("Macro",           { fg = c.pinkred })
hi("Type",            { fg = c.cyan })
hi("Special",         { fg = c.blue_dim })
hi("Delimiter",       { fg = c.fg })
hi("SpecialComment",  { fg = c.green })
hi("Underlined",      { fg = c.blue_soft, underline = true })
hi("Title",           { fg = c.blue_soft, bold = true })
hi("Directory",       { fg = c.blue_dim, bold = true })

hi("Error",           { fg = c.white, bg = c.red, bold = true })
hi("ErrorMsg",        { fg = c.red, bg = c.bg, bold = true })
hi("WarningMsg",      { fg = c.yellow, bg = c.bg, bold = true })

hi("DiagnosticError", { fg = c.red })
hi("DiagnosticWarn",  { fg = c.yellow })
hi("DiagnosticInfo",  { fg = c.blue_soft })
hi("DiagnosticHint",  { fg = c.cyan })

hi("GitSignsAdd",     { fg = "#587c0c", bg = c.bg })
hi("GitSignsChange",  { fg = "#d7ba7d", bg = c.bg })
hi("GitSignsDelete",  { fg = c.red, bg = c.bg })

hi("TelescopeNormal",         { fg = c.fg, bg = c.bg })
hi("TelescopeBorder",         { fg = "#3e3e42", bg = c.bg })
hi("TelescopePromptNormal",   { fg = c.fg, bg = c.bg })
hi("TelescopePromptBorder",   { fg = "#3e3e42", bg = c.bg })
hi("TelescopeResultsNormal",  { fg = c.fg, bg = c.bg })
hi("TelescopeResultsBorder",  { fg = "#3e3e42", bg = c.bg })
hi("TelescopePreviewNormal",  { fg = c.fg, bg = c.bg })
hi("TelescopePreviewBorder",  { fg = "#3e3e42", bg = c.bg })
hi("TelescopeSelection",      { fg = c.white, bg = "#094771" })
hi("TelescopeMatching",       { fg = c.blue_soft, bold = true })

hi("DashboardHeader",  { fg = c.white, bg = c.bg })
hi("DashboardSection", { fg = c.yellow, bg = c.bg, bold = true })
hi("DashboardItem",    { fg = c.white, bg = c.bg })
hi("DashboardFooter",  { fg = c.yellow, bg = c.bg, bold = true })

hi("NvimTreeNormal",          { fg = c.fg, bg = c.tree_bg })
hi("NvimTreeNormalNC",        { fg = c.fg, bg = c.tree_bg })
hi("NvimTreeEndOfBuffer",     { fg = c.tree_bg, bg = c.tree_bg })
hi("NvimTreeCursorLine",      { bg = c.tree_sel })
hi("NvimTreeCursorLineNr",    { fg = c.blue, bg = c.tree_sel, bold = true })
hi("NvimTreeFolderName",      { fg = c.fg, bg = c.tree_bg })
hi("NvimTreeOpenedFolderName",{ fg = c.white, bg = c.tree_bg, bold = true })
hi("NvimTreeRootFolder",      { fg = c.white, bg = c.tree_bg, bold = true })
hi("NvimTreeIndentMarker",    { fg = "#2a2d2e", bg = c.tree_bg })
hi("NvimTreeGitDirty",        { fg = "#d7ba7d", bg = c.tree_bg })
hi("NvimTreeGitNew",          { fg = "#587c0c", bg = c.tree_bg })
hi("NvimTreeGitDeleted",      { fg = c.red, bg = c.tree_bg })
hi("NvimTreeSpecialFile",     { fg = c.blue_soft, bg = c.tree_bg, underline = true })
hi("NvimTreeImageFile",       { fg = c.fg_subtle, bg = c.tree_bg })
hi("NvimTreeSymlink",         { fg = c.cyan, bg = c.tree_bg })
hi("NvimTreeExecFile",        { fg = c.green, bg = c.tree_bg })
hi("NvimTreeOpenedFile",      { fg = c.white, bg = c.tree_sel, bold = true })
hi("NvimTreeWinSeparator",    { fg = "#101010", bg = c.bg })
