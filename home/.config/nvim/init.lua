local uv = vim.uv or vim.loop
local config_dir = vim.fn.stdpath("config")
local profile_file = vim.fn.expand("~/.config/dotfiles/profile")
local profile = "safe"
if vim.fn.filereadable(profile_file) == 1 then
  profile = (vim.fn.readfile(profile_file)[1] or "safe"):gsub("%s+", "")
end
local plugins_enabled = profile == "mirror"

vim.opt.shadafile = vim.fn.stdpath("state") .. "/personal.shada"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.opt.hidden = true
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd("colorscheme ghostblack")

local capabilities = {}
if plugins_enabled then
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if vim.fn.isdirectory(lazypath) == 1 then
    vim.opt.rtp:prepend(lazypath)
    require("lazy").setup(require("plugins"), {
      change_detection = { notify = false },
      checker = { enabled = false },
    })

    local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
      capabilities = cmp_nvim_lsp.default_capabilities()
    end
  else
    vim.notify("Dotfiles mirror profile is selected but lazy.nvim is missing", vim.log.levels.WARN)
  end
end

local servers = { "lua_ls", "ts_ls", "pyright", "rust_analyzer", "clangd" }
if plugins_enabled and type(vim.lsp.config) == "function" then
  for _, server in ipairs(servers) do
    pcall(vim.lsp.config, server, { capabilities = capabilities })
  end

  local cl_lsp = vim.env.DOTFILES_CL_LSP or vim.fn.exepath("cl-lsp")
  if cl_lsp ~= "" and vim.fn.executable(cl_lsp) == 1 then
    pcall(vim.lsp.config, "cl_lsp", {
      cmd = { cl_lsp },
      filetypes = { "lisp", "commonlisp" },
      root_markers = { ".git", "*.asd" },
      capabilities = capabilities,
    })
    table.insert(servers, "cl_lsp")
  end
end
if plugins_enabled and type(vim.lsp.enable) == "function" then
  pcall(vim.lsp.enable, servers)
end

require("statusline").setup()
require("tree_setup").setup()
require("smart_quit").setup()

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("PortableDotfilesRecent", { clear = true }),
  callback = function(args)
    require("custom_dashboard").record_file(args.buf)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.schedule(function()
      if vim.fn.argc() == 0 then
        require("custom_dashboard").open()
      else
        require("tree_setup").open_for_current_file()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function()
    vim.schedule(function()
      require("tree_setup").ensure_for_current_buffer()
    end)
  end,
})
