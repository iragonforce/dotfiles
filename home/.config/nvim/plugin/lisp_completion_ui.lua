-- Purpose: reliably complete Lisp expression heads while typing.
-- Input: Insert-mode text following an opening parenthesis.
-- Output: live nvim-cmp suggestions, without competing with autodoc.
-- Nvlime's signature, server and definition integrations are untouched.

local group = vim.api.nvim_create_augroup(
  "LispCompletionUI", { clear = true }
)

local configured = {}
local generation = 0

local function form_head()
  if vim.bo.filetype ~= "lisp" then return nil end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local before = vim.api.nvim_get_current_line():sub(1, cursor[2])

  return before:match("%(%s*([%w_+*/<>=!?:%-]+)$")
end

local function configure(buf)
  if configured[buf] or not vim.api.nvim_buf_is_valid(buf)
    or vim.bo[buf].filetype ~= "lisp"
  then
    return
  end

  local ok, cmp = pcall(require, "cmp")
  if not ok then return end

  vim.api.nvim_buf_call(buf, function()
    cmp.setup.buffer({
      enabled = true,

      -- We control when the menu opens, rather than switching
      -- cmp itself on and off while the user is typing.
      completion = {
        autocomplete = false,
        keyword_length = 1,
        completeopt = "menu,menuone,noselect",
      },

      sources = cmp.config.sources({
        { name = "common_lisp", keyword_length = 1 },
      }, {
        { name = "buffer", keyword_length = 1 },
      }),

      preselect = cmp.PreselectMode.None,

      -- Nerd Font icons plus native fuzzy-match highlighting.
      formatting = {
        fields = { "kind", "abbr" },
        format = function(_, item)
          local icons = {
            Text = "",
            Method = "",
            Function = "",
            Constructor = "",
            Field = "",
            Variable = "",
            Class = "",
            Interface = "",
            Module = "",
            Property = "",
            Value = "",
            Enum = "",
            Keyword = "",
            Snippet = "",
            Constant = "",
            Operator = "",
            Struct = "",
          }

          item.kind = icons[item.kind] or ""
          item.menu = ""

          return item
        end,
      },

      view = {
        entries = {
          name = "custom",
          vertical_positioning = "below",
          selection_order = "top_down",
        },
      },
    })
  end)

  configured[buf] = true
end

local function update()
  generation = generation + 1
  local ticket = generation

  vim.defer_fn(function()
    if ticket ~= generation then return end
    if vim.fn.mode():sub(1, 1) ~= "i" then return end

    local ok, cmp = pcall(require, "cmp")
    if not ok then return end

    local head = form_head()

    if head and #head > 0 then
      -- Explicitly refresh the candidates for the current prefix.
      cmp.complete()
    elseif cmp.visible() then
      -- Arguments belong to Nvlime's signature popup.
      cmp.abort()
    end
  end, 25)
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].filetype == "lisp" then
      vim.schedule(function()
        configure(args.buf)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd({
  "TextChangedI",
  "TextChangedP",
}, {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].filetype == "lisp" then
      update()
    end
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = function()
    generation = generation + 1
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    configured[args.buf] = nil
  end,
})

vim.schedule(function()
  configure(vim.api.nvim_get_current_buf())
end)


-- Completion palette shared with Ghostblack.
-- Matched substrings and fuzzy matches are highlighted automatically
-- by nvim-cmp; this only configures their appearance.
local function apply_completion_colors()
  local colors = {
    CmpItemAbbrMatch = { fg = "#59aaff", bold = true },
    CmpItemAbbrMatchFuzzy = { fg = "#59aaff", bold = true },
    CmpItemKindFunction = { fg = "#91e500" },
    CmpItemKindMethod = { fg = "#91e500" },
    CmpItemKindKeyword = { fg = "#ff136b" },
    CmpItemKindVariable = { fg = "#59aaff" },
    CmpItemKindClass = { fg = "#d98aff" },
    CmpItemKindConstant = { fg = "#ffb400" },
    CmpItemKindText = { fg = "#e6e6e9" },
  }

  for group, opts in pairs(colors) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

apply_completion_colors()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup(
    "LispCompletionColors",
    { clear = true }
  ),
  callback = function()
    vim.schedule(apply_completion_colors)
  end,
})
