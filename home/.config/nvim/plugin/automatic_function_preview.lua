-- Automatic function definition preview.
-- Input: Insert-mode text changes or mouse movement over source code.
-- Output: non-focusable, read-only source preview from LSP definitions.
-- No buffer edits, cursor movement, or new plugin dependencies.

if vim.g.auto_function_preview_enabled == nil then
  vim.g.auto_function_preview_enabled = true
end

local preview_win
local generation = 0

local function completion_visible()
  if vim.fn.pumvisible() ~= 0 then return true end
  local ok, cmp = pcall(require, "cmp")
  return ok and cmp.visible() or false
end

local function close_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win = nil
end

local function invalidate()
  generation = generation + 1
  close_preview()
end

local function identifier_at(text, column)
  for start, word in text:gmatch("()([%a_][%w_]*)") do
    if column >= start and column < start + #word then
      if #word >= 3 then
        return word, start - 1
      end
    end
  end
end

local function show_source(location, name, screenrow, screencol, source_win)
  if completion_visible()
    or not vim.api.nvim_win_is_valid(source_win)
  then
    return
  end
  local uri = location.targetUri or location.uri
  local range = location.targetSelectionRange
    or location.targetRange
    or location.range

  if not uri or not range then return end

  local ok, target = pcall(vim.uri_to_bufnr, uri)
  if not ok then return end
  if not pcall(vim.fn.bufload, target) then return end

  local first = math.max(0, range.start.line - 2)
  local last = math.min(
    vim.api.nvim_buf_line_count(target),
    range.start.line + 19
  )

  local lines = vim.api.nvim_buf_get_lines(
    target, first, last, false
  )
  if #lines == 0 then return end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false

  local ft = vim.bo[target].filetype
  if ft ~= "" then
    vim.bo[bufnr].filetype = ft
  end

  vim.bo[bufnr].modifiable = false

  local pane_left = vim.api.nvim_win_get_position(source_win)[2]
  local pane_width = vim.api.nvim_win_get_width(source_win)

  local width = math.max(
    12,
    math.min(72, pane_width - 4, vim.o.columns - 6)
  )
  local height = math.max(1, math.min(#lines, 13, vim.o.lines - 6))

  local row = screenrow
  if row + height + 2 >= vim.o.lines then
    row = math.max(0, screenrow - height - 3)
  end

  local col = math.max(
    pane_left,
    math.min(
      screencol,
      pane_left + pane_width - width - 2,
      vim.o.columns - width - 2
    )
  )

  close_preview()

  preview_win = vim.api.nvim_open_win(bufnr, false, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 45,
    title = " " .. name .. " · "
      .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(target), ":t")
      .. ":" .. (range.start.line + 1) .. " ",
  })

  vim.wo[preview_win].wrap = true
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false

  if ft ~= "" then
    pcall(vim.treesitter.start, bufnr, ft)
  end
end

local function schedule_preview(win, line, column, sr, sc, delay, typed)
  invalidate()

  if not vim.g.auto_function_preview_enabled then return end
  if not vim.api.nvim_win_is_valid(win) then return end

  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then return end

  local text = vim.api.nvim_buf_get_lines(
    buf, line - 1, line, false
  )[1]

  if not text then return end

  local name, start_byte = identifier_at(text, column)
  if not name then return end

  if typed then
    if completion_visible() then return end

    local prefix = text:sub(1, column)
    local opens = select(2, prefix:gsub("%(", ""))
    local closes = select(2, prefix:gsub("%)", ""))

    -- While entering arguments, leave the screen to signature help.
    if vim.bo[buf].filetype ~= "lisp" and opens > closes then
      return
    end
  end

  local ticket = generation
  local tick = vim.api.nvim_buf_get_changedtick(buf)

  vim.defer_fn(function()
    if ticket ~= generation then return end
    if not vim.api.nvim_buf_is_valid(buf) then return end
    if vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
    if completion_visible() then return end

    local clients = vim.lsp.get_clients({
      bufnr = buf,
      method = "textDocument/definition",
    })

    if #clients == 0 then return end

    local client = clients[1]
    local encoding = client.offset_encoding or "utf-16"

    local params = vim.lsp.util.make_position_params(
      win, encoding
    )

    params.position.line = line - 1
    params.position.character = vim.str_utfindex(
      text, encoding, start_byte, false
    )

    client:request("textDocument/definition", params,
      function(err, result)
        if err or not result then return end
        if ticket ~= generation then return end
        if vim.api.nvim_buf_get_changedtick(buf) ~= tick then
          return
        end

        local location = vim.islist(result)
          and result[1]
          or result

        if not location then return end

        vim.schedule(function()
          if ticket == generation and not completion_visible() then
            show_source(location, name, sr, sc, win)
          end
        end)
      end, buf)
  end, delay)
end

local function from_keyboard()
  local win = vim.api.nvim_get_current_win()
  local position = vim.api.nvim_win_get_cursor(win)
  local col = position[2]

  if col < 1 then
    invalidate()
    return
  end

  local screen = vim.fn.screenpos(win, position[1], col + 1)

  schedule_preview(
    win, position[1], col,
    screen.row, screen.col, 400, true
  )
end

local function from_mouse()
  local mouse = vim.fn.getmousepos()

  if mouse.winid == 0
    or mouse.line == 0
    or mouse.column == 0
    or not vim.api.nvim_win_is_valid(mouse.winid)
  then
    invalidate()
    return
  end

  schedule_preview(
    mouse.winid, mouse.line, mouse.column,
    mouse.screenrow, mouse.screencol, 500, false
  )
end

local cmp_hooked = false

local function hook_completion()
  if cmp_hooked then return end

  local ok, cmp = pcall(require, "cmp")
  if not ok then return end

  cmp_hooked = true

  cmp.event:on("menu_opened", function()
    invalidate()
  end)

  cmp.event:on("menu_closed", function()
    vim.defer_fn(function()
      if vim.fn.mode():sub(1, 1) == "i"
        and not completion_visible()
        and vim.g.auto_function_preview_enabled
      then
        from_keyboard()
      end
    end, 200)
  end)
end

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.schedule(hook_completion)
  end,
})

vim.o.mousemoveevent = true
vim.opt.mouse = "a"

local group = vim.api.nvim_create_augroup(
  "AutomaticFunctionPreview",
  { clear = true }
)

vim.api.nvim_create_autocmd({
  "TextChangedI", "CompleteDone",
}, {
  group = group,
  callback = from_keyboard,
})

vim.api.nvim_create_autocmd({
  "InsertLeave", "BufLeave", "CursorMoved",
}, {
  group = group,
  callback = invalidate,
})

vim.keymap.set({ "n", "i" }, "<MouseMove>", from_mouse, {
  silent = true,
  desc = "Preview definition when hovering over a symbol",
})

vim.api.nvim_create_user_command(
  "AutoFunctionPreviewToggle",
  function()
    vim.g.auto_function_preview_enabled =
      not vim.g.auto_function_preview_enabled

    invalidate()

    vim.notify(
      "Automatic function preview: "
      .. (vim.g.auto_function_preview_enabled and "ON" or "OFF")
    )
  end,
  { desc = "Toggle automatic function definition previews" }
)
