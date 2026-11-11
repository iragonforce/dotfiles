local M = {}

local function current_directory()
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then
    return vim.fn.fnamemodify(file, ":p:h")
  end
  return vim.fn.getcwd()
end

local function run_in_tmux(command, title, directory)
  if not vim.env.TMUX or vim.fn.executable("tmux") ~= 1 then
    vim.notify(
      "An active tmux session is required",
      vim.log.levels.ERROR
    )
    return false
  end

  local shell = vim.env.SHELL or "/bin/zsh"

  -- Run the command, show its exit status, then
  -- keep the new tmux window open.
  local script = command
    .. "\n__nvim_exit=$?"
    .. "\nprintf '\\n[Exit status: %s]\\n' \"$__nvim_exit\""
    .. "\nexec " .. vim.fn.shellescape(shell) .. " -i"

  local output = vim.fn.system({
    "tmux",
    "new-window",
    "-c", directory,
    "-n", title,
    script,
  })

  if vim.v.shell_error ~= 0 then
    vim.notify(
      "tmux error: " .. output,
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

function M.compile_c()
  local file = vim.api.nvim_buf_get_name(0)

  if vim.bo.filetype ~= "c"
      or not file:match("%.c$") then
    vim.notify(
      "Gcc requires a C source file (.c)",
      vim.log.levels.ERROR
    )
    return
  end

  -- Save modified source before compiling.
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, "update")
    if not ok then
      vim.notify(
        "Cannot save C file: " .. tostring(err),
        vim.log.levels.ERROR
      )
      return
    end
  end

  local executable = file:sub(1, -3)
  local directory = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(executable, ":t")

  local command = table.concat({
    "gcc",
    "-Wall",
    "-Wextra",
    "-o", vim.fn.shellescape(executable),
    vim.fn.shellescape(file),
  }, " ")

  return run_in_tmux(
    command,
    "gcc:" .. name,
    directory
  )
end

function M.shell(command)
  if not command or command:match("^%s*$") then
    vim.notify(
      "Usage: :Sh <shell command>",
      vim.log.levels.WARN
    )
    return
  end

  return run_in_tmux(
    command,
    "shell",
    current_directory()
  )
end

function M.setup()
  vim.api.nvim_create_user_command(
    "Gcc",
    M.compile_c,
    { desc = "Compile current C file in tmux" }
  )

  vim.api.nvim_create_user_command(
    "Sh",
    function(opts)
      M.shell(opts.args)
    end,
    {
      nargs = "+",
      desc = "Run shell command in active tmux window",
    }
  )

  -- Allow lowercase :gcc as a shorthand.
  vim.cmd([[
    cnoreabbrev <expr> gcc
      \ getcmdtype() ==# ':' && getcmdline() ==# 'gcc'
      \ ? 'Gcc' : 'gcc'
  ]])
end

return M
