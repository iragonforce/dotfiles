local M = {}

local uv = vim.uv or vim.loop

local function hostname()
  local host = uv.os_gethostname() or vim.fn.hostname()
  return (host:gsub("%..*$", ""))
end

local function trim(text)
  return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function file_label()
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype

  if ft == "customdashboard" then
    return "dashboard"
  end

  if ft == "NvimTree" then
    return "files"
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "[No Name]"
  end

  local tail = vim.fn.fnamemodify(name, ":t")
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return tail
  end

  local icon = devicons.get_icon(tail, vim.fn.fnamemodify(name, ":e"), { default = true })
  if icon and icon ~= "" then
    return string.format("%s %s", icon, tail)
  end

  return tail
end

local function file_encoding()
  local enc = vim.bo.fileencoding
  if enc == nil or enc == "" then
    enc = vim.o.encoding
  end
  if enc == nil or enc == "" then
    enc = "utf-8"
  end
  return enc
end

function M.left()
  return string.format(" %s | %s ", hostname(), file_label())
end

function M.right()
  local total = math.max(vim.fn.line("$"), 1)
  local line = math.max(1, math.min(vim.fn.line("."), total))
  local col = math.max(1, vim.fn.col("."))
  local percent = math.floor((line / total) * 100)
  return string.format(
    " %s [%s] %d%% line: %d/%d col: %d ",
    file_encoding(),
    vim.bo.fileformat,
    percent,
    line,
    total,
    col
  )
end

return M
