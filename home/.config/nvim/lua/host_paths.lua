local M = {}
local mac = vim.fn.has("macunix") == 1
M.project_root = vim.fn.expand("~/project")
M.obsidian_root = mac
    and vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/secondBrain")
    or vim.fn.expand("~/obsidian/obsidian-vault")
function M.cl_lsp_command()
  local roswell = vim.fn.expand("~/.roswell/bin/cl-lsp")
  if mac and vim.fn.executable(roswell) == 1 then
    return { "/usr/bin/env", "DYLD_LIBRARY_PATH=" .. vim.fn.expand("~/.local/lib"), roswell }
  end
  return { "cl-lsp" }
end
return M
