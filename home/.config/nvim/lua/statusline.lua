local M = {}

local modes = {
  n = "NORMAL", no = "NORMAL", i = "INSERT", ic = "INSERT", ix = "INSERT",
  v = "VISUAL", vs = "VISUAL", V = "VISUAL", R = "REPLACE", Rc = "REPLACE",
  c = "COMMAND", t = "TERMINAL",
}

local function mode()
  return modes[vim.fn.mode()] or "NORMAL"
end

local function path()
  local name = vim.api.nvim_buf_get_name(0)
  return name == "" and "[No Name]" or vim.fn.fnamemodify(name, ":~")
end

local function git_info()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return "" end
  local dir = vim.fn.fnamemodify(name, ":p:h")
  local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not root[1] or root[1] == "" then return "" end
  local branch = vim.fn.systemlist({ "git", "-C", dir, "branch", "--show-current" })[1] or ""
  if branch == "" then branch = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--short", "HEAD" })[1] or "HEAD" end
  return string.format(" 󰊢 %s:%s", vim.fn.fnamemodify(root[1], ":t"), branch)
end

local function right()
  local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  local format = vim.bo.fileformat ~= "" and vim.bo.fileformat or "unix"
  return string.format("%s[%s] %d,%d %P", encoding, format, vim.fn.line("."), vim.fn.col("."))
end

function M.setup()
  local group = vim.api.nvim_create_augroup("PortableDotfilesStatusline", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
    group = group,
    callback = function(args)
      local win = vim.fn.bufwinid(args.buf)
      if win == -1 then return end
      if vim.bo[args.buf].filetype == "customdashboard" then
        vim.wo[win].statusline = ""
        vim.opt.laststatus = 0
        return
      end
      vim.opt.laststatus = 3
      vim.wo[win].statusline = "%{%v:lua.require('statusline').left()%}%=%{%v:lua.require('statusline').right()%}"
    end,
  })
end

function M.left()
  return "%#StatusLineMode#[" .. mode() .. "]%#StatusLine# " .. path() .. git_info()
end

function M.right()
  return right()
end

return M
