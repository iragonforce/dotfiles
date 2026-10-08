local M = {}

local mode_names = {
  n = "NORMAL",
  no = "NORMAL",
  nov = "NORMAL",
  noV = "NORMAL",
  ["no\22"] = "NORMAL",
  i = "INSERT",
  ic = "INSERT",
  ix = "INSERT",
  v = "VISUAL",
  vs = "VISUAL",
  V = "VISUAL",
  Vs = "VISUAL",
  ["\22"] = "VISUAL",
  ["\22s"] = "VISUAL",
  R = "REPLACE",
  Rc = "REPLACE",
  Rv = "V-REPLACE",
  c = "COMMAND",
  cv = "EX",
  ce = "EX",
  r = "PROMPT",
  rm = "MORE",
  t = "TERMINAL",
}

local function current_mode()
  return mode_names[vim.fn.mode()] or "NORMAL"
end

local function current_path()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return "[No Name]"
  end
  return vim.fn.fnamemodify(name, ":~")
end

local function git_info()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return ""
  end
  local directory = vim.fn.fnamemodify(name, ":p:h")
  local root = vim.fn.systemlist({ "git", "-C", directory, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not root or not root[1] or root[1] == "" then
    return ""
  end
  local branch = vim.fn.systemlist({ "git", "-C", directory, "branch", "--show-current" })
  branch = branch and branch[1] or ""
  if branch == "" then
    branch = vim.fn.systemlist({ "git", "-C", directory, "rev-parse", "--short", "HEAD" })[1] or "HEAD"
  end
  local repo = vim.fn.fnamemodify(root[1], ":t")
  return string.format(" 󰊢 %s:%s", repo, branch)
end

local function encoding()
  local value = vim.bo.fileencoding
  if value == "" then
    value = vim.o.encoding
  end
  return value == "" and "utf-8" or value
end

local function fileformat()
  return vim.bo.fileformat == "" and "unix" or vim.bo.fileformat
end

function M.left()
  return "%#StatusLineMode#[" .. current_mode() .. "]%#StatusLine# " .. current_path() .. git_info()
end

function M.right()
  local line = math.max(vim.fn.line("."), 1)
  local col = math.max(vim.fn.col("."), 1)
  return string.format("%s[%s] %d,%d", encoding(), fileformat(), line, col)
end

local function apply_window_statusline(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype == "customdashboard" then
    vim.opt.laststatus = 0
    return
  end

  vim.opt.laststatus = 3
  vim.wo[win].statusline = "%{%v:lua.require('statusline').left()%}%=%{%v:lua.require('statusline').right()%} %P"
end

function M.setup()
  apply_window_statusline(0)

  local group = vim.api.nvim_create_augroup("PersonalStatusline", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = function(args)
      apply_window_statusline(vim.fn.bufwinid(args.buf))
    end,
  })
end

return M
