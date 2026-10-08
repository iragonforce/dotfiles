local M = {}

local function has_nvim_tree()
  local ok, _ = pcall(require, "nvim-tree")
  return ok
end

function M.open_for_current_file()
  if has_nvim_tree() then
    local api = require("nvim-tree.api")
    local file = vim.fn.expand("%:p")
    if file == "" then
      file = vim.fn.argv(0)
    end
    if file == "" then
      return
    end
    local dir = vim.fn.fnamemodify(file, ":h")
    if vim.fn.isdirectory(dir) ~= 1 then
      return
    end
    vim.cmd("cd " .. vim.fn.fnameescape(dir))
    api.tree.open()
    api.tree.find_file({
      open = true,
      focus = false,
      update_root = true,
    })
    vim.cmd("wincmd p")
    return
  end

  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.netrw_winsize = 28
  vim.g.netrw_keepdir = 0
  vim.g.netrw_browse_split = 4

  local file = vim.fn.expand("%:p")
  if file == "" then
    file = vim.fn.argv(0)
  end
  if file == "" then
    return
  end

  local dir = vim.fn.fnamemodify(file, ":h")
  if vim.fn.isdirectory(dir) ~= 1 then
    return
  end

  vim.cmd("silent keepalt leftabove Lexplore " .. vim.fn.fnameescape(dir))
  vim.cmd("silent vertical resize 34")
  vim.cmd("silent setlocal winfixwidth")
  vim.cmd("silent wincmd p")
end

vim.keymap.set("n", "<leader>e", function()
  require("sidebar").open_for_current_file()
end, { silent = true })

return M
