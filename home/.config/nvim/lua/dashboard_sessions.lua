local M = {}

local function session_path()
  return vim.fn.stdpath("state") .. "/dashboard-last-session.vim"
end

local function real_file(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buftype == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function has_unsaved_changes()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].modified then
      return true
    end
  end
  return false
end

local function report(message, silent, level)
  if not silent then
    vim.notify(message, level or vim.log.levels.INFO)
  end
end

function M.save(opts)
  opts = opts or {}

  if not real_file(vim.api.nvim_get_current_buf()) then
    report("Open a file before saving a session", opts.silent)
    return false
  end

  if has_unsaved_changes() then
    report(
      "Session not saved: unsaved buffers exist. Use :wa first.",
      opts.silent,
      vim.log.levels.WARN
    )
    return false
  end

  local path = session_path()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  local temp = path .. "." .. vim.fn.getpid() .. ".tmp.vim"
  local previous = vim.o.sessionoptions

  -- Preserve files, splits, tabs and cursor positions.
  -- Exclude global options, blank windows and terminal jobs.
  vim.o.sessionoptions =
    "buffers,curdir,folds,tabpages,winsize"

  local ok, err = pcall(
    vim.cmd, "mksession! " .. vim.fn.fnameescape(temp)
  )

  vim.o.sessionoptions = previous

  if not ok then
    vim.fn.delete(temp)
    report(tostring(err), opts.silent, vim.log.levels.ERROR)
    return false
  end

  local renamed, rename_err = vim.uv.fs_rename(temp, path)

  if not renamed then
    vim.fn.delete(temp)
    report(
      tostring(rename_err),
      opts.silent,
      vim.log.levels.ERROR
    )
    return false
  end

  report("Session saved", opts.silent)
  return true
end

function M.resume()
  local path = session_path()

  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("No saved session found", vim.log.levels.WARN)
    return false
  end

  if has_unsaved_changes() then
    vim.notify(
      "Save or discard unsaved changes before restoring.",
      vim.log.levels.WARN
    )
    return false
  end

  local ok, err = pcall(
    vim.cmd, "source " .. vim.fn.fnameescape(path)
  )

  if not ok then
    vim.notify(
      "Session restoration failed: " .. tostring(err),
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

function M.setup()
  vim.api.nvim_create_user_command(
    "SessionSave", function() M.save() end, {}
  )

  vim.api.nvim_create_user_command(
    "SessionResume", function() M.resume() end, {}
  )

  vim.keymap.set("n", "<leader>ss", function()
    M.save()
  end, { desc = "Save editor session" })

  -- AUTOMATIC EDITOR SESSION SNAPSHOTS
  -- Save after editing or layout activity settles.
  -- M.save() protects existing snapshots from dashboard-only
  -- sessions and unsaved buffers.
  local save_generation = 0

  local function schedule_session_save()
    save_generation = save_generation + 1
    local generation = save_generation

    vim.defer_fn(function()
      if generation ~= save_generation then
        return
      end

      if vim.g.SessionLoad then
        return
      end

      M.save({ silent = true })
    end, 700)
  end

  vim.api.nvim_create_autocmd({
    "VimEnter",
    "BufEnter",
    "BufWritePost",
    "WinEnter",
    "WinClosed",
    "TabEnter",
    "TabClosed",
    "DirChanged",
  }, {
    group = vim.api.nvim_create_augroup(
      "DashboardSessionAutosave", { clear = true }
    ),
    callback = schedule_session_save,
  })

  vim.api.nvim_create_autocmd({
    "VimLeavePre",
    "FocusLost",
    "VimSuspend",
  }, {
    group = vim.api.nvim_create_augroup(
      "DashboardSessionSave", { clear = true }
    ),
    callback = function()
      M.save({ silent = true })
    end,
  })
end

return M
