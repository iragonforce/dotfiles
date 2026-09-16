local M = {}
local ns = vim.api.nvim_create_namespace("portable_dotfiles_dashboard")
local recent_file = vim.fn.stdpath("state") .. "/dotfiles-recent"
local project_root = vim.env.DOTFILES_PROJECT_ROOT or vim.fn.expand("~/project")
local session_recent = {}

local function read_recent()
  if vim.fn.filereadable(recent_file) == 1 then
    session_recent = vim.fn.readfile(recent_file)
  end
end

local function write_recent()
  vim.fn.mkdir(vim.fn.fnamemodify(recent_file, ":h"), "p")
  vim.fn.writefile(session_recent, recent_file)
end

local function add_file(out, seen, file)
  if not file or file == "" then return end
  file = vim.fn.resolve(vim.fn.fnamemodify(file, ":p"))
  if vim.fn.filereadable(file) == 1 and not seen[file] then
    seen[file] = true
    table.insert(out, file)
  end
end

local function recent(limit)
  read_recent()
  local out, seen = {}, {}
  for _, file in ipairs(session_recent) do
    add_file(out, seen, file)
    if #out >= limit then break end
  end
  return out
end

local function projects(limit)
  local entries = {}
  if vim.fn.isdirectory(project_root) ~= 1 then return entries end
  for name, kind in vim.fs.dir(project_root) do
    if kind == "directory" and name ~= ".git" and name ~= "node_modules" and name ~= ".venv" then
      local path = vim.fs.joinpath(project_root, name)
      local newest = vim.uv.fs_stat(path).mtime.sec
      for file, fkind in vim.fs.dir(path) do
        if fkind == "file" then
          local stat = vim.uv.fs_stat(vim.fs.joinpath(path, file))
          newest = math.max(newest, stat and stat.mtime.sec or 0)
        end
      end
      table.insert(entries, { name = name, path = path, mtime = newest })
    end
  end
  table.sort(entries, function(a, b) return a.mtime > b.mtime end)
  while #entries > limit do table.remove(entries) end
  return entries
end

local function newest_obsidian()
  local roots = {}
  if vim.env.DOTFILES_OBSIDIAN_ROOT then table.insert(roots, vim.env.DOTFILES_OBSIDIAN_ROOT) end
  table.insert(roots, vim.fn.expand("~/Documents/Obsidian"))
  table.insert(roots, vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/secondBrain"))
  local newest, newest_time
  local function walk(root)
    if vim.fn.isdirectory(root) ~= 1 then return end
    for name, kind in vim.fs.dir(root) do
      if name ~= ".obsidian" and name ~= ".git" then
        local path = vim.fs.joinpath(root, name)
        if kind == "directory" then walk(path)
        elseif kind == "file" and name:lower():sub(-3) == ".md" then
          local stat = vim.uv.fs_stat(path)
          if stat and (not newest_time or stat.mtime.sec > newest_time) then newest, newest_time = path, stat.mtime.sec end
        end
      end
    end
  end
  for _, root in ipairs(roots) do walk(root) end
  return newest
end

local function key_for(index)
  if index <= 9 then return tostring(index) end
  return string.char(string.byte("a") + index - 10)
end

local function center(text)
  local width = math.max(vim.fn.strdisplaywidth(text), 1)
  local pad = math.max(0, math.floor((vim.o.columns - width) / 2))
  return string.rep(" ", pad) .. text
end

function M.is_open(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "customdashboard"
end

function M.record_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then return end
  if M.is_open(buf) or vim.bo[buf].filetype == "NvimTree" then return end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.fn.filereadable(file) ~= 1 then return end
  file = vim.fn.resolve(vim.fn.fnamemodify(file, ":p"))
  for i = #session_recent, 1, -1 do if session_recent[i] == file then table.remove(session_recent, i) end end
  table.insert(session_recent, 1, file)
  while #session_recent > 25 do table.remove(session_recent) end
  write_recent()
end

local function open_file(file)
  vim.cmd("edit " .. vim.fn.fnameescape(file))
  require("tree_setup").open_for_current_file()
end

local function open_project(entry)
  vim.cmd("lcd " .. vim.fn.fnameescape(entry.path))
  vim.cmd("enew")
  require("tree_setup").open_directory(entry.path)
end

function M.open()
  read_recent()
  require("tree_setup").close()
  vim.opt.laststatus = 0
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "customdashboard"
  vim.bo[buf].modifiable = true

  local recent_files = recent(25)
  local project_list = projects(8)
  local lines = {
    center("NEOVIM"), "", center(" 󰘧  Keymaps "),
    center(" 󰈞  Find File                                      f"),
    center(" 󰈔  New File                                       n"),
    center(" 󰉋  Projects                                       p"),
    center(" 󰍉  Find Text                                      g"),
    center(" 󰄉  Recent Files                                   r"),
    center(" 󰉓  Obsidian                                       o"),
    center(" 󰒓  Config                                         c"),
    center(" 󰗼  Quit                                           q"), "",
    center(" 󰈔  Recent Files"),
  }
  local mappings = {}
  for index, file in ipairs(recent_files) do
    local key = key_for(index)
    table.insert(lines, center(string.format("%-70s %s", vim.fn.fnamemodify(file, ":~"), key)))
    mappings[key] = function() open_file(file) end
  end
  table.insert(lines, "")
  table.insert(lines, center(" 󰉋  Projects"))
  for _, project in ipairs(project_list) do table.insert(lines, center("  " .. project.name)) end
  table.insert(lines, "")
  table.insert(lines, center(" 󰔟  Portable dotfiles dashboard"))

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for index, line in ipairs(lines) do
    if line:find("NEOVIM", 1, true) then vim.api.nvim_buf_add_highlight(buf, ns, "DashboardHeader", index - 1, 0, -1) end
    if line:find("Keymaps", 1, true) or line:find("Recent Files", 1, true) or line:find("Projects", 1, true) then
      vim.api.nvim_buf_add_highlight(buf, ns, "DashboardSection", index - 1, 0, -1)
    end
  end
  vim.bo[buf].modifiable = false

  local function map(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true }) end
  map("f", function()
    if vim.fn.exists(":Telescope") == 2 then vim.cmd("Telescope find_files") else vim.cmd("find **/*") end
  end)
  map("n", function() vim.cmd("enew") end)
  map("p", function()
    if #project_list == 0 then return vim.notify("No projects found under " .. project_root, vim.log.levels.INFO) end
    vim.ui.select(project_list, { prompt = "Project" }, function(choice) if choice then open_project(choice) end end)
  end)
  map("g", function()
    if vim.fn.exists(":Telescope") == 2 then vim.cmd("Telescope live_grep") else vim.notify("Telescope is unavailable", vim.log.levels.INFO) end
  end)
  map("r", function() M.open() end)
  map("o", function()
    local file = newest_obsidian()
    if file then open_file(file) else vim.notify("No Obsidian Markdown file found", vim.log.levels.INFO) end
  end)
  map("c", function() vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.expand("~/.config/nvim/init.lua"))) end)
  map("q", function() vim.cmd("qa") end)
  for key, action in pairs(mappings) do map(key, action) end
end

return M
