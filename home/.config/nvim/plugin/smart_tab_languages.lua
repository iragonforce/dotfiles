-- Purpose: apply structural Tab indentation across programming languages.
-- Input: Insert-mode Tab in supported filetypes.
-- Output: completion navigation, snippet navigation, or reindentation.
-- Common Lisp retains its existing dedicated Tab implementation.
-- Makefiles, Markdown, plain text and CSV are intentionally excluded.

local group = vim.api.nvim_create_augroup(
  "ProgrammingSmartTab", { clear = true }
)

local languages = {
  python = true,
  yaml = true,
  haskell = true,

  c = true,
  cpp = true,
  java = true,
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
  lua = true,
  rust = true,
  go = true,

  sh = true,
  bash = true,
  zsh = true,

  html = true,
  css = true,
  scss = true,
  json = true,
  jsonc = true,
  toml = true,
  xml = true,

  ruby = true,
  php = true,
  swift = true,
  kotlin = true,
  scala = true,
  nix = true,
  sql = true,
}

local sensitive = {
  python = 4,
  yaml = 2,
  haskell = 2,
}

local installed = {}

local function setup(buf)
  if not vim.api.nvim_buf_is_valid(buf)
    or installed[buf]
  then
    return
  end

  local ft = vim.bo[buf].filetype

  if not languages[ft] or vim.bo[buf].buftype ~= "" then
    return
  end

  -- These languages rely on whitespace for structure.
  local width = sensitive[ft]
  if width then
    vim.bo[buf].expandtab = true
    vim.bo[buf].shiftwidth = width
    vim.bo[buf].softtabstop = width
  end

  vim.keymap.set("i", "<Tab>", function()
    local ok, cmp = pcall(require, "cmp")

    -- Navigate completion suggestions first.
    if ok and cmp.visible() then
      cmp.select_next_item({
        behavior = cmp.SelectBehavior.Select,
      })
      return ""
    end

    -- Preserve snippet expansion/navigation.
    local snip_ok, luasnip = pcall(require, "luasnip")

    if snip_ok and luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
      return ""
    end

    local line = vim.api.nvim_get_current_line()

    -- Empty lines need actual indentation for new code.
    if line:match("^%s*$") then
      return "<Tab>"
    end

    -- Existing lines use the language's indentation engine.
    return [[<C-\><C-o>==]]
  end, {
    buffer = buf,
    expr = true,
    replace_keycodes = true,
    desc = "Smart Tab: completion, snippet, or structural indent",
  })

  installed[buf] = true
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = group,
  callback = function(args)
    vim.schedule(function()
      setup(args.buf)
    end)
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    installed[args.buf] = nil
  end,
})

vim.schedule(function()
  setup(vim.api.nvim_get_current_buf())
end)
