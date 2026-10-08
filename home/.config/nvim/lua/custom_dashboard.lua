local M = {}
local ns = vim.api.nvim_create_namespace("custom_dashboard_ns")

local project_root = vim.fn.expand("~/project")
local obsidian_root = vim.fn.expand("~/obsidian/obsidian-vault")
local ignored_project_dirs = {
  [".git"] = true,
  [".venv"] = true,
  ["node_modules"] = true,
  ["build"] = true,
  ["dist"] = true,
  ["target"] = true,
  [".cache"] = true,
}
local session_recent = {}

local function open_dashboard_file(file)
  local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(file))
  if not ok then
    vim.notify(
      "Could not open " .. file .. ". Neovim reported a swap-file conflict. Use :recover " .. vim.fn.fnameescape(file) .. " if recovery is needed.",
      vim.log.levels.ERROR
    )
    return false
  end
  require("tree_setup").ensure_for_current_buffer()
  return true
end

local function shell_words(text)
  local words, current, quote, escaped = {}, {}, nil, false
  for i = 1, #text do
    local char = text:sub(i, i)
    if escaped then
      table.insert(current, char)
      escaped = false
    elseif char == "\\" and quote ~= "'" then
      escaped = true
    elseif quote ~= nil then
      if char == quote then
        quote = nil
      else
        table.insert(current, char)
      end
    elseif char == "'" or char == '"' then
      quote = char
    elseif char:match("%s") then
      if #current > 0 then
        table.insert(words, table.concat(current))
        current = {}
      end
    else
      table.insert(current, char)
    end
  end
  if #current > 0 then
    table.insert(words, table.concat(current))
  end
  return words
end

local function add_file(out, seen, candidate)
  if not candidate or candidate == "" then
    return
  end
  if candidate:sub(1, 1) == "~" then
    candidate = vim.fn.expand(candidate)
  elseif candidate:sub(1, 1) ~= "/" then
    candidate = vim.fn.fnamemodify(candidate, ":p")
  end
  candidate = vim.fn.resolve(candidate)
  if vim.fn.filereadable(candidate) == 1 and not seen[candidate] then
    seen[candidate] = true
    table.insert(out, candidate)
  end
end

local function history_recent_files(limit)
  local out, seen = {}, {}

  for _, file in ipairs(session_recent) do
    add_file(out, seen, file)
    if #out >= limit then
      return out
    end
  end

  for _, file in ipairs(vim.v.oldfiles) do
    add_file(out, seen, file)
    if #out >= limit then
      return out
    end
  end

  return out
end

local function walk_files(root, callback, skip_dirs)
  if vim.fn.isdirectory(root) ~= 1 then
    return
  end
  for name, kind in vim.fs.dir(root) do
    if not (skip_dirs and skip_dirs[name]) and name ~= ".obsidian" and name ~= ".git" then
      local path = vim.fs.joinpath(root, name)
      if kind == "directory" then
        walk_files(path, callback, skip_dirs)
      elseif kind == "file" then
        callback(path)
      end
    end
  end
end

local function newest_markdown(root)
  local newest_path, newest_time = nil, -1
  walk_files(root, function(path)
    if path:lower():sub(-3) == ".md" then
      local stat = vim.uv.fs_stat(path)
      local mtime = stat and stat.mtime and stat.mtime.sec or 0
      if mtime > newest_time then
        newest_path, newest_time = path, mtime
      end
    end
  end)
  return newest_path
end

local function project_entries(limit)
  local entries = {}
  if vim.fn.isdirectory(project_root) ~= 1 then
    return entries
  end

  for name, kind in vim.fs.dir(project_root) do
    if kind == "directory" and not ignored_project_dirs[name] then
      local path = vim.fs.joinpath(project_root, name)
      local newest = 0
      walk_files(path, function(file)
        local stat = vim.uv.fs_stat(file)
        local mtime = stat and stat.mtime and stat.mtime.sec or 0
        newest = math.max(newest, mtime)
      end, ignored_project_dirs)
      table.insert(entries, { path = path, mtime = newest })
    end
  end

  table.sort(entries, function(a, b) return a.mtime > b.mtime end)
  local out = {}
  for i = 1, math.min(limit, #entries) do
    table.insert(out, entries[i].path)
  end
  return out
end

local function recent_files(limit)
  return history_recent_files(limit)
end

local function projects(limit)
  return project_entries(limit)
end

local function center(width, text)
  local pad = math.floor((width - vim.fn.strdisplaywidth(text)) / 2)
  if pad < 0 then
    pad = 0
  end
  return string.rep(" ", pad) .. text
end

local function ellipsize(text, max_width)
  if vim.fn.strdisplaywidth(text) <= max_width then
    return text
  end
  local shortened = vim.fn.pathshorten(text)
  if vim.fn.strdisplaywidth(shortened) <= max_width then
    return shortened
  end
  while vim.fn.strdisplaywidth(shortened .. "…") > max_width and #shortened > 1 do
    shortened = shortened:sub(1, -2)
  end
  return shortened .. "…"
end

local function plugin_count()
  local base = vim.fn.expand("~/.local/share/nvim/site/pack/packer/start")
  local dirs = vim.fn.globpath(base, "*", false, true)
  local n = 0
  for _, d in ipairs(dirs) do
    if vim.fn.isdirectory(d) == 1 then
      n = n + 1
    end
  end
  return n
end

local function startup_seconds_centis()
  local elapsed_ms = vim.g.__dashboard_load_ms
  if elapsed_ms == nil then
    elapsed_ms = (vim.loop.hrtime() - (vim.g.__dashboard_start or vim.loop.hrtime())) / 1000000
  end
  local secs = math.floor(elapsed_ms / 1000)
  local centis = math.floor((elapsed_ms % 1000) / 10)
  return secs, centis
end

local function item_line(left, key, body_width)
  local pad = body_width - vim.fn.strdisplaywidth(left) - vim.fn.strdisplaywidth(key)
  if pad < 2 then
    pad = 2
  end
  return center(vim.o.columns, left .. string.rep(" ", pad) .. key)
end

local function menu_line(icon, label, key, body_width)
  return item_line("  " .. icon .. "  " .. label, key, body_width)
end

local function section_line(label)
  return center(vim.o.columns, label)
end

local function target_width(entries)
  local width = 52
  for _, entry in ipairs(entries) do
    width = math.max(width, vim.fn.strdisplaywidth(entry.left) + vim.fn.strdisplaywidth(entry.key) + 2)
  end
  return math.min(width, math.max(54, vim.o.columns - 12))
end

local function open_project(path)
  require("tree_setup").close()
  vim.cmd("lcd " .. vim.fn.fnameescape(path))
  vim.cmd("enew")
  require("tree_setup").open_directory(path)
end

local function map(buf, lhs, rhs)
  vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true })
end

function M.is_open(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "customdashboard"
end

function M.record_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  if vim.bo[buf].filetype == "customdashboard" or vim.bo[buf].filetype == "NvimTree" then
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" or vim.fn.filereadable(file) ~= 1 then
    return
  end
  file = vim.fn.resolve(vim.fn.fnamemodify(file, ":p"))
  for i = #session_recent, 1, -1 do
    if session_recent[i] == file then
      table.remove(session_recent, i)
    end
  end
  table.insert(session_recent, 1, file)
  while #session_recent > 25 do
    table.remove(session_recent)
  end
end

function M.open()
  require("tree_setup").close()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype = "customdashboard"
  vim.opt.laststatus = 0

  local width = vim.o.columns
  local lines, hls = {}, {}
  local function add(text, hl)
    table.insert(lines, text)
    if hl then
      table.insert(hls, { #lines - 1, hl })
    end
  end

  local header = {
    "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
    "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
    "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
    "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
    "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
    "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
  }

  local rf = recent_files(25)
  local ps = projects(8)
  local recent_entries = {}
  local project_entries = {}

  if #rf == 0 then
    table.insert(recent_entries, { left = "  •  empty", key = " " })
  else
    local recent_keys = "123456789ABCDEFGHIJKLMNOP"
    for i, f in ipairs(rf) do
      table.insert(recent_entries, {
        left = "  " .. ellipsize(vim.fn.fnamemodify(f, ":~"), 42),
        key = recent_keys:sub(i, i),
      })
    end
  end

  if #ps == 0 then
    table.insert(project_entries, { left = "  •  empty", key = " " })
  else
    for i, p in ipairs(ps) do
      table.insert(project_entries, {
        left = "  " .. ellipsize(vim.fn.fnamemodify(p, ":t"), 42),
        key = "F" .. i,
      })
    end
  end

  local menu_entries = {
    { left = "  󰱼  Find File", key = "f" },
    { left = "    New File", key = "n" },
    { left = "    Projects", key = "p" },
    { left = "    Find Text", key = "g" },
    { left = "    Recent Files", key = "r" },
    { left = "  󰠮  Obsidian", key = "o" },
    { left = "    Config", key = "c" },
    { left = "    Quit", key = "q" },
  }
  local body_width = target_width(vim.list_extend(vim.deepcopy(menu_entries), vim.list_extend(vim.deepcopy(recent_entries), vim.deepcopy(project_entries))))

  add("")
  add("")
  for _, l in ipairs(header) do
    add(center(width, l), "DashboardHeader")
  end
  add("")
  add(section_line("󰌌  Keymaps"), "DashboardSection")
  add(menu_line("󰱼", "Find File", "f", body_width), "DashboardItem")
  add(menu_line("", "New File", "n", body_width), "DashboardItem")
  add(menu_line("", "Projects", "p", body_width), "DashboardItem")
  add(menu_line("", "Find Text", "g", body_width), "DashboardItem")
  add(menu_line("", "Recent Files", "r", body_width), "DashboardItem")
  add(menu_line("󰠮", "Obsidian", "o", body_width), "DashboardItem")
  add(menu_line("", "Config", "c", body_width), "DashboardItem")
  add(menu_line("", "Quit", "q", body_width), "DashboardItem")
  add("")
  add(section_line("  Recent Files  (1-9, A-P)"), "DashboardSection")

  for _, entry in ipairs(recent_entries) do
    add(item_line(entry.left, entry.key, body_width), "DashboardItem")
  end

  add("")
  add(section_line("  Projects"), "DashboardSection")

  for _, entry in ipairs(project_entries) do
    add(item_line(entry.left, entry.key, body_width), "DashboardItem")
  end

  add("")
  local secs, centis = startup_seconds_centis()
  add(center(width, string.format("󰔟  Nvim loaded %d plugins in %d.%02d seconds  ", plugin_count(), secs, centis)), "DashboardFooter")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for _, item in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(buf, ns, item[2], item[1], 0, -1)
  end
  vim.bo[buf].modifiable = false

  map(buf, "f", function() require("telescope.builtin").find_files() end)
  map(buf, "n", function()
    vim.cmd("enew")
    require("tree_setup").ensure_for_current_buffer()
    vim.cmd("startinsert")
  end)
  map(buf, "p", function() require("telescope.builtin").find_files({ cwd = project_root }) end)
  map(buf, "g", function() require("telescope.builtin").live_grep() end)
  map(buf, "r", function() require("telescope.builtin").oldfiles() end)
  map(buf, "o", function()
    local file = newest_markdown(obsidian_root)
    if not file then
      vim.notify("No Obsidian Markdown files found", vim.log.levels.WARN)
      return
    end
    open_dashboard_file(file)
  end)
  map(buf, "c", function() require("host_config_menu").open() end)
  map(buf, "q", function() require("smart_quit").smart_quit() end)

  for i, project in ipairs(ps) do
    if i > 8 then
      break
    end
    map(buf, "<F" .. i .. ">", function()
      open_project(project)
    end)
  end

  local recent_keys = "123456789ABCDEFGHIJKLMNOP"
  for i, f in ipairs(rf) do
    local key = recent_keys:sub(i, i)
    if key == "" then
      break
    end
    map(buf, key, function()
      open_dashboard_file(f)
    end)
  end

end

return M
