-- Purpose: register custom Neovim commands for direct use and
-- Telescope's Command Palette.
-- Input: current source buffer and optional command bang.
-- Output: compiler/SBCL execution in a tmux pane.
-- Implementation: compiler_panes.lua.
--
-- Registered commands:
--   :Sbcl   Load current Lisp file into interactive SBCL
--   :Gcc    Compile current C file
--   :Gcc!   Compile and run current C file
--   :Clang  Compile current C file
--   :Clang! Compile and run current C file

require("compiler_panes").setup()

-- Allow lowercase aliases when entering Ex commands manually.
vim.cmd([[
  cnoreabbrev <expr> sbcl
    \ getcmdtype() ==# ':' && getcmdline() ==# 'sbcl'
    \ ? 'Sbcl' : 'sbcl'

  cnoreabbrev <expr> gcc
    \ getcmdtype() ==# ':' && getcmdline() ==# 'gcc'
    \ ? 'Gcc' : 'gcc'

  cnoreabbrev <expr> clang
    \ getcmdtype() ==# ':' && getcmdline() ==# 'clang'
    \ ? 'Clang' : 'clang'
]])
