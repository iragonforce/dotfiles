local M = {}

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("host_config_menu")

local function host()
  local name = uv.os_gethostname() or vim.fn.hostname()
  return (name:gsub("%..*$", ""))
end

local function path_exists(path)
  local expanded = vim.fn.expand(path)
  return expanded ~= "" and uv.fs_stat(expanded) ~= nil
end

local function filter_existing(items)
  local out = {}
  for _, item in ipairs(items) do
    if item.path == nil or path_exists(item.path) then
      table.insert(out, item)
    end
  end
  return out
end

local function config_definitions()
  local common = {
    {
      key = "v",
      label = "vim",
      items = {
        { label = "init.lua", path = "~/.config/nvim/init.lua" },
        { label = "dashboard", path = "~/.config/nvim/lua/custom_dashboard.lua" },
        { label = "tree setup", path = "~/.config/nvim/lua/tree_setup.lua" },
        { label = "ui overrides", path = "~/.config/nvim/plugin/ui_overrides.lua" },
      },
    },
    {
      key = "g",
      label = "ghostty",
      items = {
        { label = "ghostty config", path = "~/.config/ghostty/config" },
        { label = "ghostty mac config", path = "~/Library/Application Support/com.mitchellh.ghostty/config" },
      },
    },
    {
      key = "z",
      label = "zsh",
      items = {
        { label = ".zshrc", path = "~/.zshrc" },
        { label = ".zprofile", path = "~/.zprofile" },
        { label = "oh-my-zsh plugins", path = "~/.oh-my-zsh/custom/plugins", kind = "dir" },
      },
    },
    {
      key = "s",
      label = "ssh",
      items = {
        { label = "ssh config", path = "~/.ssh/config" },
      },
    },
    {
      key = "c",
      label = "codex",
      items = {
        { label = "AGENTS.md", path = "~/.codex/AGENTS.md" },
        { label = "codex config", path = "~/.codex/config.toml" },
        { label = "agents mcp", path = "~/project/agents/mcp.json" },
        { label = "mcp compose", path = "~/project/mcp/docker-compose.yml" },
      },
    },
  }

  local by_host = {
    nexus = {
      {
        key = "d",
        label = "docker",
        items = {
          { label = "docker daemon", path = "/etc/docker/daemon.json" },
          { label = "docker stack", path = "/mnt/fast/docker", kind = "dir" },
          { label = "nginx data", path = "/mnt/fast/nginx", kind = "dir" },
        },
      },
    },
    tensor = {
      {
        key = "h",
        label = "hyprland",
        items = {
          { label = "hyprland.conf", path = "~/.config/hypr/hyprland.conf" },
          { label = "hypr config dir", path = "~/.config/hypr", kind = "dir" },
        },
      },
    },
  }

  local out = {}
  for _, item in ipairs(common) do
    item.items = filter_existing(item.items)
    if #item.items > 0 then
      table.insert(out, item)
    end
  end

  for _, item in ipairs(by_host[host()] or {}) do
    item.items = filter_existing(item.items)
    if #item.items > 0 then
      table.insert(out, item)
    end
  end

  return out
end

local function close_window(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

local function redraw_picker(buf, title, items, selected)
  local lines = { " " .. title .. " ", "" }
  for index, item in ipairs(items) do
    table.insert(lines, string.format(" %d. %s", index, item.label))
  end
  table.insert(lines, "")
  table.insert(lines, " enter: open   q/esc: close ")

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "DashboardSection", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "DashboardFooter", #lines - 1, 0, -1)

  for index = 1, #items do
    local line = index + 1
    local hl = index == selected and "CursorLineNr" or "DashboardItem"
    vim.api.nvim_buf_add_highlight(buf, ns, hl, line, 0, -1)
  end
  vim.bo[buf].modifiable = false
end

local function open_path(target)
  local tree = require("tree_setup")
  local path = vim.fn.expand(target.path)

  if target.kind == "dir" then
    tree.open_directory(path)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))
  tree.ensure_for_current_buffer()
end

local function picker(title, items, on_select)
  local width = 0
  for _, item in ipairs(items) do
    width = math.max(width, vim.fn.strdisplaywidth(item.label) + 5)
  end
  width = math.max(width, vim.fn.strdisplaywidth(title) + 4, 38)
  local height = #items + 4
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "configpicker"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    row = math.max(row, 1),
    col = math.max(col, 1),
    width = width,
    height = height,
  })

  local selected = 1

  local function refresh()
    redraw_picker(buf, title, items, selected)
    vim.api.nvim_win_set_cursor(win, { selected + 2, 0 })
  end

  local function move(delta)
    selected = ((selected - 1 + delta) % #items) + 1
    refresh()
  end

  local function choose(index)
    close_window(win)
    on_select(items[index or selected])
  end

  refresh()

  vim.keymap.set("n", "j", function() move(1) end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "k", function() move(-1) end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Down>", function() move(1) end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Up>", function() move(-1) end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<CR>", function() choose() end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "q", function() close_window(win) end, { buffer = buf, silent = true, nowait = true })
  vim.keymap.set("n", "<Esc>", function() close_window(win) end, { buffer = buf, silent = true, nowait = true })

  for index = 1, math.min(#items, 9) do
    vim.keymap.set("n", tostring(index), function() choose(index) end, {
      buffer = buf,
      silent = true,
      nowait = true,
    })
  end
end

function M.open()
  local categories = config_definitions()
  if #categories == 0 then
    return
  end

  picker(string.format("%s config", host()), categories, function(category)
    picker(category.label, category.items, function(item)
      open_path(item)
    end)
  end)
end

return M
