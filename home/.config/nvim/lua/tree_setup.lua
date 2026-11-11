local M = {}
local state = {
  syncing = false,
  last_target = nil,
}

local ok_tree, nvim_tree = pcall(require, "nvim-tree")
if ok_tree then
  nvim_tree.setup({
    hijack_cursor = false,
    sync_root_with_cwd = false,
    respect_buf_cwd = false,
    view = {
      width = 34,
      side = "left",
      preserve_window_proportions = true,
      number = false,
      relativenumber = false,
      signcolumn = "no",
    },
    renderer = {
      root_folder_label = function()
        return "../"
      end,
      highlight_git = true,
      highlight_opened_files = "name",
      indent_markers = { enable = true },
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
        glyphs = {
          default = "󰈚",
          symlink = "",
          bookmark = "󰆤",
          folder = {
            arrow_closed = "",
            arrow_open = "",
            default = "",
            open = "",
            empty = "",
            empty_open = "",
            symlink = "",
            symlink_open = "",
          },
          git = {
            unstaged = "M",
            staged = "S",
            unmerged = "",
            renamed = "R",
            untracked = "U",
            deleted = "D",
            ignored = "◌",
          },
        },
      },
    },
    filters = {
      dotfiles = false,
      git_ignored = false,
    },
    update_focused_file = {
      enable = true,
      update_root = false,
    },
    git = {
      enable = true,
      ignore = false,
      timeout = 400,
      disable_for_dirs = {
        vim.env.HOME,
      },
    },
    actions = {
      open_file = {
        quit_on_open = false,
        resize_window = false,
      },
    },
  })
end

local function current_target_file()
  local file = vim.fn.expand("%:p")
  if file == "" then
    file = vim.fn.argv(0)
  end
  if file == "" then
    return nil
  end
  return file
end

function M.close()
  if ok_tree then
    require("nvim-tree.api").tree.close()
  end
end

function M.is_tree_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.bo[buf].filetype == "NvimTree"
end

function M.open_directory(path)
  if not ok_tree then
    return
  end

  local stat = vim.uv.fs_stat(path)
  if not stat then
    return
  end

  local dir = stat.type == "directory"
    and path or vim.fn.fnamemodify(path, ":h")

  -- Explicit project-root selection.
  -- Use project markers when opening files.
  local root = dir

  if stat.type == "file" then
    root = vim.fs.root(path, {
      ".git",
      "pyproject.toml",
      "Cargo.toml",
      "go.mod",
      "pom.xml",
      "build.gradle",
      "package.json",
      "cabal.project",
      "stack.yaml",
    }) or dir
  end

  local api = require("nvim-tree.api")
  local previous_win = vim.api.nvim_get_current_win()
  local previous_buf = vim.api.nvim_get_current_buf()

  api.tree.open({ path = root })
  api.tree.change_root(root)

  if stat.type == "file" then
    api.tree.find_file({
      buf = path,
      open = true,
      focus = false,
      update_root = false,
    })

    if vim.api.nvim_win_is_valid(previous_win)
        and vim.api.nvim_buf_is_valid(previous_buf)
        and not M.is_tree_buffer(previous_buf) then
      pcall(vim.api.nvim_set_current_win, previous_win)
    end
  end
end

function M.ensure_for_current_buffer()
  if not ok_tree then
    return
  end
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  if M.is_tree_buffer(buf) or vim.bo[buf].filetype == "customdashboard" or vim.bo[buf].buftype ~= "" then
    return
  end
  if state.syncing then
    return
  end
  local file = current_target_file()
  if file == nil then
    return
  end
  file = vim.fn.fnamemodify(file, ":p")
  if state.last_target == file and require("nvim-tree.api").tree.is_visible() then
    return
  end

  state.syncing = true
  local ok, err = pcall(M.open_directory, file)
  state.syncing = false

  if ok then
    state.last_target = file
    return
  end

  vim.schedule(function()
    vim.notify(err, vim.log.levels.ERROR)
  end)
end

function M.open_for_current_file()
  local file = current_target_file()
  if file == nil then
    return
  end
  M.open_directory(file)
end

vim.keymap.set("n", "<leader>e", function()
  if not ok_tree then
    return
  end

  local api = require("nvim-tree.api")

  if api.tree.is_visible() then
    api.tree.close()
  else
    M.open_for_current_file()
  end
end, { silent = true, desc = "Toggle project explorer" })

return M
