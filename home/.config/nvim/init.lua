local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- Ignore the obsolete Packer copies. They shadow Lazy's current Mason plugins
-- and cause mason.nvim/mason-lspconfig API mismatches.
local legacy_plugin_root = vim.fn.stdpath("data") .. "/site/pack/packer/start"
for _, plugin in ipairs({
  "mason.nvim", "mason-lspconfig.nvim", "nvim-cmp", "cmp-nvim-lsp",
  "cmp-buffer", "cmp-cmdline", "cmp-path", "cmp_luasnip", "LuaSnip",
  "nvim-lspconfig", "nvim-treesitter",
}) do
  vim.opt.rtp:remove(legacy_plugin_root .. "/" .. plugin)
end

-- Keep personal Neovim's ShaDa history separate from barebones `nvim`.
vim.opt.shadafile = vim.fn.stdpath("state") .. "/personal.shada"

require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local languages = {
        "bash", "c", "cpp", "css", "commonlisp", "go", "html", "java",
        "javascript", "json", "lua", "markdown", "markdown_inline", "python",
        "query", "rust", "toml", "typescript", "tsx", "vim", "vimdoc", "yaml",
      }

      require("nvim-treesitter").setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })
      vim.treesitter.language.register("commonlisp", { "lisp" })
      require("nvim-treesitter").install(languages)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "bash", "c", "cpp", "css", "html", "java", "javascript", "json",
          "lua", "markdown", "python", "rust", "sh", "typescript", "typescriptreact",
          "lisp", "toml", "yaml",
        },
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end,
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = {},
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "bashls", "clangd", "cssls", "gopls", "html", "jdtls", "jsonls",
        "lua_ls", "pyright", "rust_analyzer", "ts_ls", "yamlls",
      },
      automatic_enable = false,
    },
  },

  {
    "monkoose/nvlime",
    lazy = false,
    ft = { "lisp" },
    dependencies = { "monkoose/parsley", "hrsh7th/nvim-cmp" },
    init = function()
      vim.g.nvlime_config = {
        implementation = "sbcl",
        cmp = { enabled = true },
        autodoc = { enabled = true },
        main_window = { position = "right", size = 40 },
      }
    end,
    config = function()
      local cmp = require("cmp")
      cmp.setup.filetype({ "lisp" }, {
        sources = cmp.config.sources({
          { name = "common_lisp", keyword_length = 1 },
          { name = "nvlime" },
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  {
    "Vigemus/iron.nvim",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local common = require("iron.fts.common")

      iron.setup({
        config = {
          scratch_repl = true,
          repl_definition = {
            python = {
              command = { "python3", "-i", "-q" },
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
              env = { PYTHON_BASIC_REPL = "1" },
            },
            java = { command = { "jshell" } },
            lisp = {
              command = vim.fn.executable("rlwrap") == 1
                  and { "rlwrap", "-H", vim.fn.expand("~/.sbcl_history"), "sbcl" }
                  or { "sbcl" },
            },
          },
          repl_open_cmd = view.split.vertical.botright(0.38),
          repl_filetype = function(_, ft)
            return ft
          end,
        },
        keymaps = {
          toggle_repl = "<leader>ir",
          restart_repl = "<leader>rR",
          send_motion = "<leader>sc",
          visual_send = "<leader>sc",
          send_file = "<leader>sf",
          send_line = "<leader>sl",
          send_paragraph = "<leader>sp",
          interrupt = "<leader>si",
          exit = "<leader>sq",
          clear = "<leader>sx",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      })
    end,
  },

  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },

  {
    "neovim/nvim-lspconfig",
  },

  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.register_source("common_lisp", require("common_lisp_completion"))

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
          { name = "luasnip" },
        }),
      })

      cmp.setup.filetype({ "lisp" }, {
        sources = cmp.config.sources({
          { name = "common_lisp", keyword_length = 1 },
          { name = "nvlime", keyword_length = 1 },
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- nvim-lspconfig now provides server definitions for Neovim's native LSP API.
-- Keep configuration here so it remains compatible with nvim-lspconfig 3.0.
for _, server in ipairs({
  "bashls", "clangd", "cssls", "gopls", "html", "jdtls",
  "jsonls", "lua_ls", "pyright", "rust_analyzer", "ts_ls", "yamlls",
}) do
  vim.lsp.config(server, {
    capabilities = capabilities,
  })
end

-- JDTLS needs a workspace root. Fall back to the directory of standalone files.
vim.lsp.config("jdtls", {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
})

-- Common Lisp's cl-lsp is not shipped by nvim-lspconfig, so define it here.
vim.lsp.config("cl_lsp", {
  cmd = { "cl-lsp" },
  filetypes = { "lisp" },
  root_markers = { ".git", "*.asd" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { ".git", "*.asd" })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
  capabilities = capabilities,
})

vim.lsp.enable({
  "bashls", "clangd", "cssls", "gopls", "html", "jdtls", "jsonls", "lua_ls",
  "pyright", "rust_analyzer", "ts_ls", "yamlls",
})

-- Nvlime's MREPL is not a readline terminal. Make the default Lisp REPL use
-- Iron + rlwrap so Up/Down history and terminal line editing work reliably.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lisp",
  callback = function(args)
    local function nvlime_connected()
      local ok, connection = pcall(vim.fn["nvlime#connection#Get"], true)
      return ok and connection ~= vim.NIL
    end

    local function lsp_supports(method)
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
        if client.supports_method and client:supports_method(method) then
          return true
        end
      end
      return false
    end

    local function static_lisp_help()
      local symbol = vim.fn.expand("<cword>"):lower()
      local signature = require("common_lisp_completion").signature(symbol)
      if not signature then
        return false
      end
      vim.lsp.util.open_floating_preview({ signature }, "lisp", { border = "rounded" })
      return true
    end

    local function show_documentation()
      if nvlime_connected() then
        vim.cmd("call nvlime#plugin#DocumentationSymbol(nvlime#ui#CurAtom())")
      elseif lsp_supports("textDocument/hover") then
        vim.lsp.buf.hover()
      else
        static_lisp_help()
      end
    end

    local function show_definition()
      if nvlime_connected() then
        vim.cmd("call nvlime#plugin#FindDefinition(nvlime#ui#CurAtom())")
      elseif lsp_supports("textDocument/definition") then
        vim.lsp.buf.definition()
      else
        vim.notify("Start NVLIME with <leader>rn or Lisp LSP with <leader>rl for definitions", vim.log.levels.INFO)
      end
    end

    local function show_signature()
      if nvlime_connected() then
        vim.fn["nvlime#plugin#CurAutodoc"]()
      elseif lsp_supports("textDocument/signatureHelp") then
        vim.lsp.buf.signature_help()
      else
        static_lisp_help()
      end
    end

    vim.keymap.set("n", "<leader>rr", function()
      vim.cmd("IronRepl lisp")
    end, { buffer = args.buf, desc = "Open rlwrap SBCL REPL" })
    vim.keymap.set("n", "<leader>rn", "<Cmd>call nvlime#server#New(v:true, v:false)<CR>", {
      buffer = args.buf,
      desc = "Start Nvlime SBCL server",
    })
    vim.keymap.set("n", "<leader>rl", function()
      vim.lsp.enable("cl_lsp")
      vim.notify("Common Lisp LSP started", vim.log.levels.INFO)
    end, { buffer = args.buf, desc = "Start Common Lisp LSP" })
    vim.keymap.set("n", "gd", show_definition, { buffer = args.buf, desc = "Go to Lisp definition" })
    vim.keymap.set("n", "K", show_documentation, { buffer = args.buf, desc = "Show Lisp documentation" })
    vim.keymap.set({ "n", "i" }, "<C-k>", show_signature, { buffer = args.buf, desc = "Show Lisp argument list" })

  end,
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.__dashboard_start = vim.loop.hrtime()
vim.g.__dashboard_load_ms = nil
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.laststatus = 3
vim.opt.showmode = false

-- In tmux, send :! commands to a right-side pane instead of running them
-- through Neovim's command-line shell.
local function run_shell_command_in_tmux()
  if vim.fn.getcmdtype() ~= ":" then
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end

  local line = vim.fn.getcmdline()

  local smart_commands = {
    q = "smart_quit",
    ["q!"] = "smart_force_quit",
    wq = "smart_write_quit",
    x = "smart_write_quit",
  }
  local smart_command = smart_commands[line]
  if smart_command then
    vim.schedule(function()
      require("smart_quit")[smart_command]()
    end)
    return vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
  end

  local command = line:match("^!%s*(.-)%s*$")
  if not command or command == "" or vim.env.TMUX == nil or vim.fn.executable("tmux") ~= 1 then
    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  end

  local shell = vim.env.SHELL or "/bin/zsh"
  local script = command .. "\nexec " .. vim.fn.shellescape(shell) .. " -i"
  vim.fn.jobstart({
    "tmux",
    "split-window",
    "-h",
    "-c",
    vim.fn.getcwd(),
    shell,
    "-lic",
    script,
  }, { detach = true })

  return vim.api.nvim_replace_termcodes("<C-c>", true, false, true)
end

vim.keymap.set("c", "<CR>", run_shell_command_in_tmux, {
  expr = true,
  desc = "Run :! commands in a tmux pane",
})

vim.cmd("colorscheme ghostblack")
require("ui_overrides")

local function apply_transparency()
  local groups = {
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "EndOfBuffer",
    "SignColumn", "FoldColumn", "LineNr", "CursorLine", "CursorColumn",
    "ColorColumn", "VertSplit", "WinSeparator", "StatusLine", "StatusLineNC",
    "TabLine", "TabLineFill", "NvimTreeNormal", "NvimTreeNormalNC",
    "NvimTreeEndOfBuffer", "NvimTreeWinSeparator",
  }
  for _, group in ipairs(groups) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = "none"
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end

apply_transparency()
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = function()
    vim.schedule(apply_transparency)
  end,
})

local function apply_code_highlights()
  local groups = {
    ["@comment"] = { link = "Comment" },
    ["@string"] = { link = "String" },
    ["@number"] = { link = "Number" },
    ["@boolean"] = { link = "Boolean" },
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@operator"] = { link = "Operator" },
    ["@function"] = { link = "Function" },
    ["@function.call"] = { link = "Function" },
    ["@function.builtin"] = { link = "Function" },
    ["@method"] = { link = "Function" },
    ["@method.call"] = { link = "Function" },
    ["@variable"] = { fg = "#9cdcfe" },
    ["@variable.builtin"] = { fg = "#4ec9b0" },
    ["@variable.member"] = { fg = "#75beff" },
    ["@property"] = { fg = "#75beff" },
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { fg = "#4ec9b0", bold = true },
    ["@constructor"] = { fg = "#4ec9b0", bold = true },
    ["@namespace"] = { fg = "#c586c0" },
    ["@punctuation.bracket"] = { fg = "#d4d4d4" },
    ["@punctuation.delimiter"] = { fg = "#808080" },
    ["@tag"] = { fg = "#569cd6" },
    ["@tag.attribute"] = { fg = "#9cdcfe" },
  }
  for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

apply_code_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_code_highlights,
})

require("statusline").setup()

require("tree_setup")
require("smart_quit").setup()

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("PersonalRecentFiles", { clear = true }),
  callback = function(args)
    require("custom_dashboard").record_file(args.buf)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.g.__dashboard_load_ms == nil then
      vim.g.__dashboard_load_ms = (vim.loop.hrtime() - (vim.g.__dashboard_start or vim.loop.hrtime())) / 1000000
    end
    if vim.fn.argc() == 0 then
      vim.schedule(function()
        require("custom_dashboard").open()
      end)
    else
      vim.schedule(function()
        require("tree_setup").open_for_current_file()
      end)
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  callback = function()
    vim.schedule(function()
      require("tree_setup").ensure_for_current_buffer()
    end)
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.schedule(function()
      if require("custom_dashboard").is_open(0) then
        require("custom_dashboard").open()
      end
    end)
  end,
})
