-- Make Homebrew tools available in tmux on macOS.
if vim.fn.isdirectory("/opt/homebrew/bin") == 1 then
  vim.env.PATH = "/opt/homebrew/bin:" .. vim.env.PATH
end
require("clipboard_keys").setup()
local host = require("host_paths")
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
    "folke/which-key.nvim",
    lazy = false,
    config = function()
      require("which_key_setup").setup()
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("git_signs_setup").setup()
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = false,
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        objc = { "clang_format" },

        python = { "ruff_format" },
        rust = { "rustfmt" },
        lua = { "stylua" },
        haskell = { "fourmolu" },

        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },

        sh = { "shfmt" },
        bash = { "shfmt" },
        go = { "gofmt" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
    },
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

      -- Explicit formatting only; preserve existing formatter settings.
      vim.api.nvim_create_user_command("Format", function(cmd)
        local range = nil

        if cmd.range > 0 then
          local line = vim.api.nvim_buf_get_lines(
            0, cmd.line2 - 1, cmd.line2, false
          )[1] or ""

          range = {
            start = { cmd.line1, 0 },
            ["end"] = { cmd.line2, #line },
          }
        end

        conform.format({
          async = true,
          timeout_ms = 3000,
          lsp_format = "fallback",
          range = range,
        })
      end, {
        range = true,
        desc = "Format current file or selected lines",
      })

      if vim.fn.maparg("<leader>cf", "n") == "" then
        vim.keymap.set("n", "<leader>cf", "<cmd>Format<CR>", {
          silent = true,
          desc = "Code: format current file",
        })
      end

      vim.keymap.set("n", "<leader>lf", function()
        conform.format({
          async = true,
          timeout_ms = 3000,
          lsp_format = "fallback",
        })
      end, { desc = "Format current file" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local languages = {
        "bash", "c", "cpp", "css", "commonlisp", "go", "html", "haskell", "java",
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
          "bash", "c", "cpp", "css", "html", "haskell", "java", "javascript", "json",
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
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
      bind = true,
      floating_window = true,
      floating_window_above_cur_line = true,
      floating_window_off_x = 1,
      doc_lines = 12,
      max_height = 16,
      max_width = function()
        return math.max(
          40,
          math.floor(vim.api.nvim_win_get_width(0) * 0.65)
        )
      end,
      wrap = true,
      hint_enable = false,
      fix_pos = false,
      always_trigger = false,
      extra_trigger_chars = { "(", "," },
      handler_opts = { border = "rounded" },
      hi_parameter = "LspSignatureActiveParameter",
      zindex = 60,
    },
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
        cmp = { enabled = false },
        autodoc = { enabled = true },
        main_window = { position = "right", size = 40 },
      }
    end,
    config = function()
      local cmp = require("cmp")
      cmp.setup.filetype({ "lisp" }, {
        sources = cmp.config.sources({
          { name = "common_lisp", keyword_length = 1 },
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
      local luasnip = require("luasnip")
      cmp.register_source("common_lisp", require("common_lisp_completion"))

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        completion = {
          keyword_length = 1,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        formatting = {
          format = function(entry, item)
            item.menu = ({
              nvim_lsp = "[LSP]",
              buffer = "[Buffer]",
              path = "[Path]",
              luasnip = "[Snippet]",
              common_lisp = "[Lisp]",
              nvlime = "[REPL]",
            })[entry.source.name]
            return item
          end,
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
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

-- LuaLS: avoid treating an entire home directory as a workspace.
vim.lsp.config("lua_ls", {
  root_dir = function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == "" then return end

    local function real(path)
      return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
    end

    local function within(path, dir)
      return path == dir or path:sub(1, #dir + 1) == dir .. "/"
    end

    local file = real(name)
    local config = real(vim.fn.stdpath("config"))
    local home = real(vim.fn.expand("~"))
    local owner_home = real(vim.fn.expand("~iragonforce"))

    local root
    if within(file, config) then
      root = config
    else
      root = vim.fs.root(file, {
        ".luarc.json", ".luarc.jsonc",
        ".stylua.toml", "stylua.toml",
        ".luacheckrc", "selene.toml", ".git",
      })

      root = root and real(root) or nil

      if root == home or root == owner_home then
        root = nil
      end

      root = root or real(vim.fs.dirname(file))
    end

    if root == home or root == owner_home then
      on_dir(nil) -- Single-file mode, without a home workspace.
    else
      on_dir(root)
    end
  end,
})

-- JDTLS needs a workspace root. Fall back to the directory of standalone files.
vim.lsp.config("jdtls", {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "mvnw", "gradlew", "pom.xml", "build.gradle", ".git" })
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
})

-- Common Lisp's cl-lsp is not shipped by nvim-lspconfig, so define it here.
vim.lsp.config("cl_lsp", {
  cmd = host.cl_lsp_command(),
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

-- Haskell: use the installed language server when available.
if vim.fn.executable("haskell-language-server-wrapper") == 1 then
  vim.lsp.config("hls", {
    capabilities = capabilities,
  })
  vim.lsp.enable("hls")
end

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
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
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

require("ghostblack_semantics").setup()

require("statusline").setup()

require("tree_setup")
-- Native :q/:q!/:wq/:x; dashboard remains startup-only.
require("dashboard_sessions").setup()
require("dashboard_actions").setup()
require("tmux_commands").setup()

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

vim.opt.foldenable = false

-- All custom command registrations are centralized here.
require("config.commands")

require("function_guidance").setup()
