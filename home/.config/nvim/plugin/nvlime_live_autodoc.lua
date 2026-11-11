-- Purpose: refresh Nvlime's current SBCL lambda list while typing.
-- Input: Lisp Insert-mode edits and cursor movement.
-- Output: Nvlime autodoc request and a local diagnostic status file.
-- Does not alter completion sources or Lisp source buffers.

local group = vim.api.nvim_create_augroup(
  "NvlimeLiveAutodoc", { clear = true }
)

local generation = 0
local status_file = vim.fn.stdpath("state")
  .. "/nvlime-live-autodoc-status.txt"

local function record(message)
  pcall(vim.fn.writefile, {
    os.date("%Y-%m-%d %H:%M:%S") .. " " .. message,
  }, status_file)
end

record("Loaded; waiting for Lisp Insert mode")

local function refresh()
  generation = generation + 1
  local ticket = generation
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  if vim.bo[buf].filetype ~= "lisp" then return end

  vim.defer_fn(function()
    if ticket ~= generation
      or not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_win_is_valid(win)
      or vim.api.nvim_get_current_buf() ~= buf
      or vim.fn.mode():sub(1, 1) ~= "i"
    then
      return
    end

    local ok, conn = pcall(
      vim.fn["nvlime#connection#Get"], true
    )

    if not ok or conn == nil or conn == vim.NIL then
      record("DISCONNECTED: reconnect Nvlime to SBCL")
      return
    end

    local success, err = pcall(
      vim.fn["nvlime#plugin#CurAutodoc"]
    )

    if success then
      record("CONNECTED: autodoc request issued")
    else
      record("ERROR: " .. tostring(err))
    end
  end, 180)
end

vim.api.nvim_create_autocmd({
  "TextChangedI",
  "TextChangedP",
  "CursorMovedI",
}, {
  group = group,
  pattern = "*.lisp",
  callback = refresh,
})

-- Covers buffers with Lisp filetype but nonstandard filenames.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "lisp",
  callback = function(args)
    vim.api.nvim_create_autocmd({
      "TextChangedI",
      "TextChangedP",
      "CursorMovedI",
    }, {
      group = group,
      buffer = args.buf,
      callback = refresh,
    })
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = group,
  callback = function()
    generation = generation + 1
  end,
})

vim.api.nvim_create_user_command("LispAutodocRefresh", function()
  refresh()
end, {
  desc = "Refresh the current SBCL function argument list",
})
