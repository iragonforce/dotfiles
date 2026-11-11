-- Purpose: compile C files or load Common Lisp files in a 50% tmux pane.
-- Input: the current Neovim file; optional ! to compile and run C files.
-- Output: a new active tmux pane, compilation results or an interactive SBCL.
-- The source file is updated before execution. The result pane remains open.

local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.ERROR)
end

local function quoted(value)
  return vim.fn.shellescape(value)
end

local function current_file()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    notify("No file is open")
    return nil
  end

  local ok, err = pcall(vim.cmd, "update")
  if not ok then
    notify("Could not save file: " .. tostring(err))
    return nil
  end

  return vim.fn.fnamemodify(file, ":p")
end

local function split(command, directory)
  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    notify("This command requires Neovim inside a tmux pane")
    return
  end

  local args = {
    "tmux",
    "split-window",
    "-h",
    "-p", "50",
    "-t", vim.env.TMUX_PANE,
    "-c", directory,
    "sh", "-c", command,
  }

  local output = vim.fn.system(args)

  if vim.v.shell_error ~= 0 then
    notify("tmux split failed: " .. output)
  end
end

local function compile(compiler, run_after)
  local file = current_file()
  if not file then return end

  if not file:match("%.c$") then
    notify("Expected a .c source file")
    return
  end

  if vim.fn.executable(compiler) ~= 1 then
    notify(compiler .. " is not installed or not in PATH")
    return
  end

  local directory = vim.fn.fnamemodify(file, ":h")
  local executable = vim.fn.fnamemodify(file, ":r")

  local compile_command = table.concat({
    compiler,
    "-Wall -Wextra -g",
    "-o", quoted(executable),
    quoted(file),
  }, " ")

  local lines = {
    'printf "\\n[Compiling with ' .. compiler .. ']\\n"',
    compile_command,
    'status=$?',
    'printf "\\n[Compilation exit code: %s]\\n" "$status"',
  }

  if run_after then
    table.insert(lines,
      'if [ "$status" -eq 0 ]; then')
    table.insert(lines,
      '  ' .. quoted(executable))
    table.insert(lines,
      '  status=$?')
    table.insert(lines,
      '  printf "\\n[Program exit code: %s]\\n" "$status"')
    table.insert(lines, 'fi')
  end

  table.insert(lines, 'exec "${SHELL:-/bin/sh}" -i')

  split(table.concat(lines, "\n"), directory)
end

local function sbcl()
  local file = current_file()
  if not file then return end

  local valid = file:match("%.lisp$")
    or file:match("%.lsp$")
    or file:match("%.cl$")
    or file:match("%.asd$")

  if not valid then
    notify("Expected a Common Lisp file (.lisp, .lsp, .cl, .asd)")
    return
  end

  if vim.fn.executable("sbcl") ~= 1 then
    notify("SBCL is not installed or not in PATH")
    return
  end

  local directory = vim.fn.fnamemodify(file, ":h")

  local command = table.concat({
    'printf "\\n[Loading Common Lisp file]\\n"',
    'sbcl --load ' .. quoted(file),
    'status=$?',
    'printf "\\n[SBCL exit code: %s]\\n" "$status"',
    'exec "${SHELL:-/bin/sh}" -i',
  }, "\n")

  split(command, directory)
end

function M.setup()
  vim.api.nvim_create_user_command("Gcc", function(opts)
    compile("gcc", opts.bang)
  end, {
    bang = true,
    force = true,
    desc = "Compile current C file in a 50% tmux pane; ! runs it",
  })

  vim.api.nvim_create_user_command("Clang", function(opts)
    compile("clang", opts.bang)
  end, {
    bang = true,
    force = true,
    desc = "Compile current C file with Clang; ! runs it",
  })

  vim.api.nvim_create_user_command("Sbcl", sbcl, {
    force = true,
    desc = "Load current Common Lisp file into SBCL in a 50% tmux pane",
  })
end

return M
