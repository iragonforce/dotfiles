local function apply_ui_overrides()
  local white = "#ffffff"
  local yellow = "#f4ce73"
  local black = "NONE"

  vim.api.nvim_set_hl(0, "StatusLine",       { fg = white, bg = black })
  vim.api.nvim_set_hl(0, "StatusLineNC",     { fg = white, bg = black })
  vim.api.nvim_set_hl(0, "StatusLineTerm",   { fg = white, bg = black })
  vim.api.nvim_set_hl(0, "StatusLineTermNC", { fg = white, bg = black })
  vim.api.nvim_set_hl(0, "StatusLineMode",   { fg = yellow, bg = black, bold = true })
  vim.api.nvim_set_hl(0, "LineNr",           { fg = yellow, bg = black })
  vim.api.nvim_set_hl(0, "CursorLineNr",     { fg = yellow, bg = black, bold = true })
  vim.api.nvim_set_hl(0, "SignColumn",       { fg = yellow, bg = black })
  vim.api.nvim_set_hl(0, "FoldColumn",       { fg = yellow, bg = black })

  vim.g.airline_theme = "base16"
  vim.g.airline_left_sep = ""
  vim.g.airline_right_sep = ""
  vim.g.airline_left_alt_sep = ""
  vim.g.airline_right_alt_sep = ""
  vim.g["airline#extensions#nvimtree#enabled"] = 0
  vim.cmd([[
    let g:airline#themes#base16#palette = {}
    let g:airline#themes#base16#palette.normal = {
          \ 'airline_a': ['#f4ce73', '', 0, 1, ''],
          \ 'airline_b': ['#f4ce73', '', 0, 1, ''],
          \ 'airline_c': ['#ffffff', '', 0, 0, ''],
          \ 'airline_x': ['#ffffff', '', 0, 0, ''],
          \ 'airline_y': ['#ffffff', '', 0, 0, ''],
          \ 'airline_z': ['#f4ce73', '', 0, 1, ''],
          \ }
    let g:airline#themes#base16#palette.insert = copy(g:airline#themes#base16#palette.normal)
    let g:airline#themes#base16#palette.visual = copy(g:airline#themes#base16#palette.normal)
    let g:airline#themes#base16#palette.replace = copy(g:airline#themes#base16#palette.normal)
    let g:airline#themes#base16#palette.inactive = {
          \ 'airline_a': ['#f4ce73', '', 0, 0, ''],
          \ 'airline_b': ['#f4ce73', '', 0, 0, ''],
          \ 'airline_c': ['#ffffff', '', 0, 0, ''],
          \ 'airline_x': ['#ffffff', '', 0, 0, ''],
          \ 'airline_y': ['#ffffff', '', 0, 0, ''],
          \ 'airline_z': ['#f4ce73', '', 0, 0, ''],
          \ }
    let g:airline_section_a = ''
    let g:airline_section_b = '%{v:lua.require("airline_context").left()}'
    let g:airline_section_c = ''
    let g:airline_section_x = ''
    let g:airline_section_y = ''
    let g:airline_section_z = '%{v:lua.require("airline_context").right()}'
  ]])
  vim.cmd("silent! AirlineRefresh")
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = function()
    vim.schedule(apply_ui_overrides)
  end,
})

vim.schedule(apply_ui_overrides)
