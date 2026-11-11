local M = {}

local function telescope()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("Telescope unavailable", vim.log.levels.ERROR)
    return nil
  end
  return builtin
end

function M.open_buffers()
  local builtin = telescope()
  if not builtin then return end

  builtin.buffers({
    sort_mru = true,
    ignore_current_buffer = true,
    prompt_title = "Open Buffers",

    attach_mappings = function(prompt_bufnr, map)
      local telescope_actions = require("telescope.actions")

      local function return_to_dashboard()
        telescope_actions.close(prompt_bufnr)

        vim.schedule(function()
          M.home()
        end)
      end

      map({ "i", "n" }, "<Esc>", return_to_dashboard)
      map({ "i", "n" }, "<C-c>", return_to_dashboard)
      map("n", "q", return_to_dashboard)

      return true
    end,
  })
end

function M.browse_notes()
  local builtin = telescope()
  if not builtin then return end

  local root = require("host_paths").obsidian_root

  if not root or vim.fn.isdirectory(root) ~= 1 then
    vim.notify("Obsidian vault unavailable", vim.log.levels.WARN)
    return
  end

  builtin.find_files({
    cwd = root,
    prompt_title = "Obsidian Notes",
    find_command = {
      "find", ".",
      "-path", "./.obsidian", "-prune",
      "-o", "-type", "f",
      "-name", "*.md", "-print",
    },
  })
end

function M.problems()
  local diagnostics = vim.diagnostic.get()

  if #diagnostics == 0 then
    vim.notify("No diagnostics in loaded buffers")
    return
  end

  vim.diagnostic.setqflist({
    open = true,
    title = "Workspace Diagnostics",
  })
end

function M.commands()
  local builtin = telescope()
  if builtin then
    builtin.commands({
      prompt_title = "Command Palette",
    })
  end
end

function M.home()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].filetype == "customdashboard" then
    return
  end

  if vim.bo[buf].modified then
    vim.notify(
      "Save or discard changes before returning to the dashboard",
      vim.log.levels.WARN
    )
    return
  end

  pcall(function()
    require("dashboard_sessions").save({ silent = true })
  end)

  local ok, err = pcall(function()
    require("custom_dashboard").open()
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>bd", M.home, {
    desc = "Back to dashboard",
  })
end

return M
