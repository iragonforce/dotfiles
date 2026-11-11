local M = {}

local function is_dashboard(buf)
  return require("custom_dashboard").is_open(buf)
end

local function is_tree(buf)
  return vim.bo[buf].filetype == "NvimTree"
end

local function is_real_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if not vim.bo[buf].buflisted then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if is_dashboard(buf) or is_tree(buf) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" and not vim.bo[buf].modified then
    return false
  end
  return true
end

local function real_buffers(exclude)
  local out = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= exclude and is_real_buffer(buf) then
      table.insert(out, buf)
    end
  end
  return out
end

local function bounce_to_dashboard(old_buf, force)
  require("tree_setup").close()
  require("custom_dashboard").open()
  if vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = force })
  end
end

local function smart_close(opts)
  local buf = vim.api.nvim_get_current_buf()

  if is_dashboard(buf) then
    vim.cmd(opts.force and "qa!" or "confirm qall")
    return
  end

  if not is_real_buffer(buf) then
    vim.cmd(opts.force and "quit!" or "confirm quit")
    return
  end

  if opts.write then
    vim.cmd("write")
  end

  if vim.bo[buf].modified and not opts.force then
    vim.notify(
      "Unsaved changes. Use :wq to save or :q! to discard.",
      vim.log.levels.WARN
    )
    return
  end

  if not opts.force then
    pcall(function()
      require("dashboard_sessions").save({ silent = true })
    end)
  end

  bounce_to_dashboard(buf, opts.force)
end

function M.smart_quit()
  smart_close({ write = false, force = false })
end

function M.smart_force_quit()
  smart_close({ write = false, force = true })
end

function M.smart_write_quit()
  smart_close({ write = true, force = false })
end

function M.setup()
  vim.api.nvim_create_user_command("DashboardSmartQuit", function()
    require("smart_quit").smart_quit()
  end, {})

  vim.api.nvim_create_user_command("DashboardSmartForceQuit", function()
    require("smart_quit").smart_force_quit()
  end, {})

  vim.api.nvim_create_user_command("DashboardSmartWriteQuit", function()
    require("smart_quit").smart_write_quit()
  end, {})

  vim.cmd([[
    cnoreabbrev <expr> q getcmdtype() ==# ':' && getcmdline() ==# 'q' ? 'DashboardSmartQuit' : 'q'
    cnoreabbrev <expr> q! getcmdtype() ==# ':' && getcmdline() ==# 'q!' ? 'DashboardSmartForceQuit' : 'q!'
    cnoreabbrev <expr> wq getcmdtype() ==# ':' && getcmdline() ==# 'wq' ? 'DashboardSmartWriteQuit' : 'wq'
    cnoreabbrev <expr> x getcmdtype() ==# ':' && getcmdline() ==# 'x' ? 'DashboardSmartWriteQuit' : 'x'
  ]])
end

return M
