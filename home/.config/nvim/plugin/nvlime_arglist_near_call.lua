-- Purpose: position Nvlime's live SBCL argument list beside the cursor.
-- Input: Nvlime's existing autodoc result and source window position.
-- Output: a non-focusable, cursor-adjacent floating signature window.
-- Does not modify Nvlime, completion sources, or source buffers.

local function install()
  local ok, arglist = pcall(require, "nvlime.window.arglist")
  if not ok or type(arglist.show) ~= "function" then
    return
  end

  if arglist._near_call_installed then
    return
  end

  local original_show = arglist.show

  arglist.show = function(content)
    local source_win = vim.api.nvim_get_current_win()
    local source_buf = vim.api.nvim_get_current_buf()

    local is_lisp =
      vim.bo[source_buf].filetype == "lisp"
      and vim.api.nvim_win_get_config(source_win).relative == ""

    local cursor
    local position

    if is_lisp then
      cursor = vim.api.nvim_win_get_cursor(source_win)
      position = vim.fn.screenpos(
        source_win,
        cursor[1],
        cursor[2] + 1
      )
    end

    -- Let Nvlime generate the content, highlights and existing window.
    local result = original_show(content)

    if not is_lisp or type(result) ~= "table" then
      return result
    end

    local float = result[1]
    local buffer = result[2]

    if type(float) ~= "number"
      or not vim.api.nvim_win_is_valid(float)
      or not vim.api.nvim_buf_is_valid(buffer)
      or not position
      or position.row == 0
    then
      return result
    end

    local pane_width = vim.api.nvim_win_get_width(source_win)
    local pane_height = vim.api.nvim_win_get_height(source_win)

    if pane_width < 18 or pane_height < 5 then
      return result
    end

    local lines = vim.api.nvim_buf_get_lines(
      buffer, 0, -1, false
    )

    local longest = 0
    for _, line in ipairs(lines) do
      longest = math.max(
        longest,
        vim.fn.strdisplaywidth(line)
      )
    end

    local width = math.max(
      12,
      math.min(longest + 2, 90, pane_width - 4)
    )

    local wrapped_height = 0
    for _, line in ipairs(lines) do
      wrapped_height = wrapped_height + math.max(
        1,
        math.ceil(vim.fn.strdisplaywidth(line) / width)
      )
    end

    local height = math.max(1, math.min(wrapped_height, 6))

    local origin = vim.api.nvim_win_get_position(source_win)
    local cursor_row = math.max(
      0,
      math.min(pane_height - 1, position.row - origin[1] - 1)
    )

    local above = cursor_row
    local below = pane_height - cursor_row - 1

    -- Always place signatures above the expression.
    -- If no space exists above, hide rather than jump below.
    local available = above
    if available < 3 then
      pcall(vim.api.nvim_win_hide, float)
      return result
    end

    height = math.min(height, available - 2)

    local row = cursor_row - height - 2

    local cursor_col = math.max(
      0,
      position.col - origin[2] - 1
    )

    local col = math.min(
      cursor_col,
      pane_width - width - 2
    )

    local moved = pcall(vim.api.nvim_win_set_config, float, {
      relative = "win",
      win = source_win,
      row = row,
      col = math.max(0, col),
      width = width,
      height = height,
      border = "rounded",
      focusable = false,
      zindex = 55,
    })

    if moved then
      vim.wo[float].wrap = true
      vim.wo[float].linebreak = true
    end

    return result
  end

  arglist._near_call_installed = true
end

local group = vim.api.nvim_create_augroup(
  "NvlimeArglistNearCall",
  { clear = true }
)

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "lisp",
  callback = install,
})

vim.schedule(function()
  if vim.bo.filetype == "lisp" then
    install()
  end
end)

vim.api.nvim_create_user_command("LispPopupStatus", function()
  local arglist = package.loaded["nvlime.window.arglist"]
  local ready = arglist and arglist._near_call_installed

  print("Nvlime near-cursor popup:", ready and "ENABLED" or "NOT LOADED")
end, {})
