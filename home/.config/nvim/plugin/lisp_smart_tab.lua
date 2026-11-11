-- Purpose: use structural indentation instead of fixed tab
-- increments in Common Lisp.
-- Input: Tab in a Lisp buffer.
-- Output: completion selection, snippet navigation, or reindent.
-- Scope: Lisp only.

local group = vim.api.nvim_create_augroup(
  "LispSmartTab", { clear = true }
)

local function setup(buf)
  if not vim.api.nvim_buf_is_valid(buf)
    or vim.bo[buf].filetype ~= "lisp"
    or vim.b[buf].lisp_smart_tab_installed
  then
    return
  end

  -- Two-space increments when literal whitespace is needed.
  vim.bo[buf].expandtab = true
  vim.bo[buf].shiftwidth = 2
  vim.bo[buf].softtabstop = 2

  vim.keymap.set("i", "<Tab>", function()
    local ok, cmp = pcall(require, "cmp")

    if ok and cmp.visible() then
      cmp.select_next_item({
        behavior = cmp.SelectBehavior.Select,
      })
      return ""
    end

    local snip_ok, luasnip = pcall(require, "luasnip")

    if snip_ok and luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
      return ""
    end

    -- On an empty line, insert ordinary indentation.
    if vim.api.nvim_get_current_line():match("^%s*$") then
      return "<Tab>"
    end

    -- On an existing expression, recompute Lisp indentation
    -- without adding another fixed-width indentation level.
    return [[<C-\><C-o>==]]
  end, {
    buffer = buf,
    expr = true,
    replace_keycodes = true,
    desc = "Lisp: completion or structural indentation",
  })

  vim.b[buf].lisp_smart_tab_installed = true
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = group,
  callback = function(args)
    vim.schedule(function()
      setup(args.buf)
    end)
  end,
})

vim.schedule(function()
  setup(vim.api.nvim_get_current_buf())
end)
