-- Purpose: show LSP function documentation and source previews.
-- Input: current symbol, attached language server and completion items.
-- Output: floating help windows; the source buffer remains unchanged.

local M = {}

local function floating_options()
  return {
    border = "rounded",
    max_width = math.max(40, math.min(90, vim.o.columns - 8)),
    max_height = math.max(6, math.min(20, vim.o.lines - 8)),
    wrap = true,
    focusable = true,
  }
end

local function peek_definition()
  local source = vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({
    bufnr = source,
    method = "textDocument/definition",
  })

  if #clients == 0 then
    vim.notify("No definition-capable LSP attached", vim.log.levels.WARN)
    return
  end

  local client = clients[1]
  local params = vim.lsp.util.make_position_params(
    0, client.offset_encoding
  )

  client:request("textDocument/definition", params, function(err, result)
    if err or not result then
      vim.notify("Definition unavailable", vim.log.levels.WARN)
      return
    end

    local location = vim.islist(result) and result[1] or result
    if not location then
      vim.notify("Definition not found", vim.log.levels.INFO)
      return
    end

    local uri = location.targetUri or location.uri
    local range = location.targetSelectionRange
      or location.targetRange
      or location.range

    if not uri or not range then
      return
    end

    local ok, target = pcall(vim.uri_to_bufnr, uri)
    if not ok then
      vim.notify("Cannot preview this definition URI", vim.log.levels.WARN)
      return
    end

    local loaded = pcall(vim.fn.bufload, target)
    if not loaded then
      vim.notify("Cannot load definition source", vim.log.levels.WARN)
      return
    end

    local line = range.start.line
    local first = math.max(0, line - 2)
    local last = math.min(
      vim.api.nvim_buf_line_count(target),
      line + 20
    )

    local lines = vim.api.nvim_buf_get_lines(
      target, first, last, false
    )

    if #lines == 0 then
      return
    end

    local filetype = vim.bo[target].filetype
    if filetype == "" then
      filetype = "text"
    end

    local options = floating_options()
    options.title = " Definition: " ..
      vim.fn.fnamemodify(vim.api.nvim_buf_get_name(target), ":t") ..
      ":" .. (line + 1) .. " "

    local preview_buf = vim.lsp.util.open_floating_preview(
      lines, filetype, options
    )

    if preview_buf and filetype ~= "text" then
      pcall(vim.treesitter.start, preview_buf, filetype)
    end
  end, source)
end

function M.setup()
  vim.api.nvim_create_user_command("PeekDefinition", peek_definition, {
    desc = "Preview function definition without navigating away",
  })

  vim.api.nvim_create_user_command("FunctionDocs", function()
    vim.lsp.buf.hover(floating_options())
  end, {
    desc = "Show function documentation",
  })

  vim.api.nvim_create_user_command("SignatureHelp", function()
    vim.lsp.buf.signature_help(floating_options())
  end, {
    desc = "Show function signature and active parameter",
  })

  vim.keymap.set("n", "<leader>lp", peek_definition, {
    desc = "Preview LSP function definition",
  })

  vim.keymap.set("n", "<leader>lh", function()
    vim.lsp.buf.hover(floating_options())
  end, {
    desc = "Show function documentation",
  })

  -- Enhance documentation for completion candidates without changing
  -- existing completion sources or key mappings.
  vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    callback = function()
      vim.schedule(function()
        local ok, cmp = pcall(require, "cmp")
        if not ok then return end

        cmp.setup({
          window = {
            documentation = cmp.config.window.bordered({
              max_width = 72,
              max_height = 18,
            }),
          },
        })
      end)
    end,
  })

  local function apply_highlight()
    vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
      fg = "#000000",
      bg = "#ffb400",
      bold = true,
    })
  end

  apply_highlight()

  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      vim.schedule(apply_highlight)
    end,
  })
end

return M
