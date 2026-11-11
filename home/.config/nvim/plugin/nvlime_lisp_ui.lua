-- Purpose: hide the Nvlime startup console after connecting and
-- offer function-name completion only at the head of Lisp forms.
-- Input: Nvlime connection state and Lisp Insert-mode edits.
-- Output: an unobstructed editor with live argument guidance.
-- The SBCL job and its console buffer remain available.

local group = vim.api.nvim_create_augroup(
  "NvlimeLispUI", { clear = true }
)

local function connected()
  for _, server in pairs(vim.g.nvlime_servers or {}) do
    if type(server) == "table"
      and tonumber(server.port or 0) > 0
      and type(server.connections) == "table"
      and next(server.connections) ~= nil
    then
      return true
    end
  end
  return false
end

-- Hide only the startup console's window, never its buffer or job.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "nvlime_server",
  callback = function(args)
    local buf = args.buf
    local attempts = 0

    local function poll()
      attempts = attempts + 1
      if not vim.api.nvim_buf_is_valid(buf) then return end

      if connected() then
        vim.defer_fn(function()
          if not connected() then return end

          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            if vim.api.nvim_win_is_valid(win) then
              pcall(vim.api.nvim_win_hide, win)
            end
          end
        end, 600)
      elseif attempts < 240 then
        vim.defer_fn(poll, 250)
      end
    end

    vim.defer_fn(poll, 250)
  end,
})

-- Lisp completion is managed by lisp_completion_ui.lua.

-- Reopen the original console when startup logs are needed.
vim.api.nvim_create_user_command("LispServerConsole", function()
  for _, server in pairs(vim.g.nvlime_servers or {}) do
    vim.fn["nvlime#server#Show"](server)
    return
  end
  vim.notify("No Nvlime-managed SBCL server is running")
end, {})

vim.api.nvim_create_user_command("LispUIStatus", function()
  local count = 0
  for _ in pairs(vim.g.nvlime_servers or {}) do
    count = count + 1
  end

  print(
    "Nvlime servers:", count,
    "| connected:", connected(),
    "| Lisp completion: native nvim-cmp"
  )
end, {})
