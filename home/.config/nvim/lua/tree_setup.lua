local M = {}
local ok_tree, tree = pcall(require, "nvim-tree")

function M.setup()
  if not ok_tree then return end
  tree.setup({
    hijack_cursor = false,
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    view = { width = 34, side = "left", preserve_window_proportions = true },
    renderer = {
      root_folder_label = "../",
      highlight_git = true,
      highlight_opened_files = "name",
      indent_markers = { enable = true },
      icons = { show = { file = true, folder = true, folder_arrow = true, git = true } },
    },
    filters = { dotfiles = false, git_ignored = false },
    update_focused_file = { enable = true, update_root = true },
    git = { enable = true, ignore = false },
    actions = { open_file = { quit_on_open = false, resize_window = false } },
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      local opts = { buffer = bufnr, silent = true, nowait = true }
      vim.keymap.set("n", "..", api.tree.change_root_to_parent, opts)
      vim.keymap.set("n", "<CR>", api.node.open.edit, opts)
    end,
  })
  vim.keymap.set("n", "<leader>e", function() require("nvim-tree.api").tree.toggle({ find_file = true }) end, { silent = true })
end

function M.close()
  if ok_tree then pcall(require("nvim-tree.api").tree.close) end
end

function M.open_directory(path)
  if not ok_tree then return end
  local stat = vim.uv.fs_stat(path)
  if not stat then return end
  local dir = stat.type == "directory" and path or vim.fn.fnamemodify(path, ":h")
  vim.cmd("silent noautocmd lcd " .. vim.fn.fnameescape(dir))
  local api = require("nvim-tree.api")
  if not api.tree.is_visible() then api.tree.open() end
  if stat.type == "file" then api.tree.find_file({ open = true, focus = false, update_root = true }) end
end

function M.open_for_current_file()
  local file = vim.fn.expand("%:p")
  if file ~= "" then M.open_directory(file) end
end

function M.ensure_for_current_buffer()
  local buf = vim.api.nvim_get_current_buf()
  if not ok_tree or vim.bo[buf].buftype ~= "" or vim.bo[buf].filetype == "customdashboard" then return end
  local file = vim.fn.expand("%:p")
  if file ~= "" then M.open_directory(file) end
end

return M
