-- Searchable and paged normal-mode motions reference.
-- Neovim native '/' and '?' provide Vim-style regex search; n/N repeat.
-- Keep categories ordered so editing and regex examples appear at the end.
local groups = {
  { "ESSENTIAL NAVIGATION", {
    { "h / j / k / l", "Left / down / up / right" },
    { "w / W", "Next word / next whitespace-delimited WORD" },
    { "b / B", "Previous word / previous WORD" },
    { "e / E", "End of current or next word / WORD" },
    { "ge / gE", "End of previous word / WORD" },
    { "0 / ^ / $", "Start of line / first nonblank / end of line" },
    { "g_", "Last nonblank character on line" },
    { "gg / G", "First / last line; {count}G jumps to that line" },
    { "42gg / 42G", "Go to line 42" },
    { "50%", "Go to approximately 50 percent through file" },
    { "5|", "Go to screen column 5" },
    { "Enter / + / -", "Next line / next first nonblank / previous first nonblank" },
    { "f{x} / F{x}", "Find character x forward / backward on line" },
    { "t{x} / T{x}", "Move just before / just after character x" },
    { "; / ,", "Repeat last f/F/t/T / repeat in reverse direction" },
    { "%", "Jump between matching paired delimiters" },
    { "H / M / L", "Top / middle / bottom of visible window" },
    { "g0 / g^ / g$", "Start / first nonblank / end of displayed line" },
    { "gj / gk", "Down / up one displayed line when lines wrap" },
  } },
  { "LONG-DISTANCE MOTIONS AND JUMPS", {
    { ") / (", "Next / previous sentence" },
    { "} / {", "Next / previous paragraph" },
    { "]] / [[", "Next / previous section boundary (filetype-dependent)" },
    { "Ctrl+O / Ctrl+I", "Jump backward / forward through locations" },
    { "g; / g,", "Previous / next location in change list" },
    { "`` / ''", "Return to previous jump position / its line" },
    { "ma", "Set local mark a at cursor" },
    { "`a / 'a", "Go to mark a exact position / line" },
    { "mA / `A", "Set / jump to file mark A across files" },
    { "`. / '.", "Go to last edit position / last edited line" },
    { "gi", "Start Insert mode where it was last stopped" },
    { ":marks / :jumps", "Inspect saved marks / navigation history" },
    { ":changes", "List positions where text changed" },
  } },
  { "SCROLLING AND WINDOW POSITION", {
    { "Ctrl+F / Ctrl+B", "Forward / backward one page" },
    { "Ctrl+D / Ctrl+U", "Down / up half a page" },
    { "Ctrl+E / Ctrl+Y", "Scroll display down / up one line" },
    { "zz / zt / zb", "Place current line center / top / bottom" },
    { "z. / z<Enter>", "Center / top screen and go to first nonblank" },
    { "Ctrl+L", "Redraw display" },
  } },
  { "INSERTING AND BASIC EDITING", {
    { "i / a", "Insert before / after cursor" },
    { "I / A", "Insert at first nonblank / line end" },
    { "o / O", "Insert line below / above" },
    { "Esc / Ctrl+[", "Return to Normal mode" },
    { "x / X", "Delete character under / before cursor" },
    { "s / S", "Substitute character / entire line" },
    { "r{x} / R", "Replace one character / enter Replace mode" },
    { "J / gJ", "Join lines with / without adding space" },
    { "u / Ctrl+R", "Undo / redo" },
    { ".", "Repeat most recent change" },
    { "U", "Undo all most recent changes on current line" },
    { "Ctrl+A / Ctrl+X", "Increment / decrement number under cursor" },
    { "3Ctrl+A", "Increase number by three" },
    { "gU / gu / g~", "Uppercase / lowercase / swap case operators" },
    { "~", "Swap case of character (default tildeop off)" },
    { ":earlier 5m", "Move undo history to approximately five minutes ago" },
    { ":later 5m", "Redo changes undone with :earlier" },
  } },
  { "OPERATORS AND COUNTS", {
    { "d{motion}", "Delete through the specified motion: dw, d$, d}" },
    { "c{motion}", "Change through the motion: cw, c$, ci(" },
    { "y{motion}", "Yank (copy) through the motion: yw, y$" },
    { "dd / cc / yy", "Delete / change / yank entire line" },
    { "D / C / Y", "Delete to EOL / change to EOL / yank line" },
    { "3dd / d3w", "Delete three lines / three words" },
    { "2j / 3w", "Move two lines down / three words forward" },
    { "p / P", "Put after / before cursor" },
    { "gp / gP", "Put after / before; leave cursor after inserted text" },
    { ">> / <<", "Indent / dedent line; add count for more lines" },
    { ">{motion}", "Indent text covered by a motion" },
    { "={motion}", "Auto-indent text covered by a motion" },
    { "gq{motion}", "Format or reflow text covered by motion" },
    { "gqap / gqq", "Reflow a paragraph / current line" },
    { "!{motion}", "Filter motion text through a shell command" },
    { "zf{motion}", "Create fold over motion (if fold method permits)" },
  } },
  { "TEXT OBJECTS: USE AFTER d / c / y / v", {
    { "iw / aw", "Inner word / word including adjacent whitespace" },
    { "iW / aW", "Inner WORD / whitespace-bounded WORD" },
    { "i\" / a\"", "Inside double quotes / include quotes" },
    { "i' / a'", "Inside single quotes / include quotes" },
    { "i` / a`", "Inside backticks / include backticks" },
    { "i( / a(", "Inside parentheses / include parentheses" },
    { "i[ / a[", "Inside square brackets / include brackets" },
    { "i{ / a{", "Inside braces / include braces" },
    { "i< / a<", "Inside angle brackets / include brackets" },
    { "it / at", "Inside HTML or XML tag / include surrounding tag" },
    { "is / as", "Inside sentence / include surrounding whitespace" },
    { "ip / ap", "Inside paragraph / include adjacent blank lines" },
    { "ciw / daw", "Change inner word / delete a word and whitespace" },
    { "ci\" / da(", "Change quoted contents / delete parenthesized text" },
    { "vip / yip", "Visually select paragraph / yank paragraph" },
    { "gn / gN", "Select next / previous match of latest search" },
    { "cgn / dgn", "Change / delete next matching search result" },
  } },
  { "SEARCH AND REGEX", {
    { "/pattern", "Search forward; Vim regular expressions are supported" },
    { "?pattern", "Search backward using same regular-expression syntax" },
    { "n / N", "Repeat search / repeat in opposite direction" },
    { "* / #", "Search whole word under cursor forward / backward" },
    { "g* / g#", "Search cursor word as substring forward / backward" },
    { "/\\v", "Prefix for very magic: () | + ? {} are regex operators" },
    { "/\\V", "Prefix for very nomagic: search almost literally" },
    { "\\c / \\C", "Force case-insensitive / case-sensitive matching" },
    { "\\<word\\>", "Whole-word boundaries in Vim regex" },
    { "^ / $", "Match beginning / end of line in a search pattern" },
    { "\\d / \\s / \\w", "Digit / whitespace / word-character regex classes" },
    { ".* / \\+", "Any characters / one-or-more (default magic mode)" },
    { "/word/e", "Move to end of found match (search offset)" },
    { ":noh", "Temporarily clear search highlighting" },
    { "q/ / q?", "Edit search history using command-line window" },
  } },
  { "SUBSTITUTION AND QUICKFIX", {
    { ":%s/old/new/g", "Replace all occurrences in whole file" },
    { ":%s/old/new/gc", "Replace globally, asking for each occurrence" },
    { ":s/old/new/g", "Replace all matches on current line" },
    { ":'<,'>s/old/new/g", "Replace matches within Visual-selected lines" },
    { ":%s/\\v(foo|bar)/X/g", "Replace foo or bar using very-magic alternation" },
    { ":g/TODO/p", "Print all lines containing TODO" },
    { ":g/TODO/d", "Delete all lines containing TODO" },
    { ":v/TODO/d", "Delete lines that do not contain TODO" },
    { ":vimgrep /TODO/g **/*.lua", "Search files and fill quickfix list" },
    { ":copen / :cclose", "Open / close quickfix list" },
    { ":cnext / :cprev", "Next / previous quickfix result" },
    { ":lopen / :lnext", "Open location list / next location" },
  } },
  { "VISUAL AND BLOCK EDITING", {
    { "v / V / Ctrl+V", "Character / line / block Visual mode" },
    { "o / O", "Switch active end of Visual selection / block corner" },
    { "gv", "Reselect last Visual selection" },
    { "d / y / c", "Delete / yank / change selected text" },
    { "> / < / =", "Indent / dedent / reindent selection" },
    { "U / u / ~", "Uppercase / lowercase / swap selected text" },
    { "I / A in block", "Insert / append to each selected block line; finish Esc" },
    { "g Ctrl+G", "Character, word, line count for selected region" },
  } },
  { "REGISTERS AND CLIPBOARD", {
    { "\"ayy / \"ap", "Yank a line to register a / put its contents" },
    { "\"Ayy", "Append yanked line to register a" },
    { "\"+y / \"+p", "Yank / put from system clipboard register" },
    { "\"*p", "Paste from primary selection where supported" },
    { "\"0p", "Put contents of most recent yank register" },
    { "\"_dd", "Delete line without changing ordinary registers" },
    { "\".p", "Put last inserted text (register dot)" },
    { ":reg / :reg a", "List registers / inspect specific register" },
    { "Ctrl+R a", "In Insert mode, insert register a contents" },
  } },
  { "MACROS AND REPEATED ACTIONS", {
    { "qa ... q", "Record macro in register a; q stops recording" },
    { "qA ... q", "Append to recorded macro a" },
    { "@a / @@", "Execute macro a / rerun most recent macro" },
    { "5@a", "Execute macro a five times" },
    { ". / 10.", "Repeat previous edit once / ten times" },
    { ":normal @a", "Execute macro a using Normal commands on line" },
  } },
  { "WINDOWS, BUFFERS, TABS, FILES", {
    { ":w / :q / :wq", "Save / quit / save and quit (smart quit may apply)" },
    { ":e path / :edit", "Open a file / reload current buffer" },
    { ":ls / :b 3", "List buffers / open buffer 3" },
    { ":bn / :bp / :bd", "Next / previous buffer / delete buffer" },
    { "Ctrl+^", "Switch to alternate buffer" },
    { ":split / :vsplit", "Split horizontally / vertically" },
    { "Ctrl+W h/j/k/l", "Focus neighboring split" },
    { "Ctrl+W w / p", "Cycle through windows / previous window" },
    { "Ctrl+W = / q", "Equalize split sizes / close split" },
    { "Ctrl+W H/J/K/L", "Move current split to far left/bottom/top/right" },
    { ":tabnew / :tabclose", "Open / close tab page" },
    { "gt / gT / 3gt", "Next / previous / third tab page" },
    { ":pwd / :cd path", "Show / change current working directory" },
    { "gf / Ctrl+W f", "Open file under cursor / open it in split" },
    { "Ctrl+G", "Display filename, position and file information" },
  } },
  { "FOLDS, SPELLING, COMMAND LINE", {
    { "za / zo / zc", "Toggle / open / close fold under cursor" },
    { "zR / zM", "Open all folds / close all folds" },
    { "zj / zk", "Next / previous fold boundary" },
    { "]s / [s", "Next / previous misspelled word (spell enabled)" },
    { "z= / zg / zw", "Spelling suggestions / mark good / mark bad" },
    { ":set spell", "Turn spelling detection on for current window" },
    { "q:", "Open editable command-line history window" },
    { "Ctrl+R =", "Insert evaluated expression in Insert or command mode" },
    { ":help topic", "Open built-in Neovim documentation" },
    { ":help motion.txt", "Complete built-in motion reference" },
    { ":help pattern.txt", "Complete built-in regex syntax" },
  } },
  { "LSP AND CUSTOM QUANTUM CONFIGURATION", {
    { "K", "Hover documentation if LSP attached" },
    { "gd", "Go to definition (LSP if mapped; else Vim local definition)" },
    { "grn / grr / gra", "Rename / references / code actions in Neovim 0.12" },
    { "<leader>e", "Toggle NvimTree explorer (this config)" },
    { "<leader>lf", "Format current buffer with Conform (this config)" },
    { ":Gcc", "Compile current C source into same folder (this config)" },
    { ":Sh echo test", "Run a shell command in new tmux window (this config)" },
    { ":Motions", "Open this quick-reference popup" },
  } },
  { "PRACTICAL EDITING EXAMPLES", {
    { "ciw", "Change word: cursor on apple, type ciw then pear<Esc>" },
    { "ci\"", "Change just text between double quotes, keep quotes" },
    { "da(", "Delete parenthesized expression including parentheses" },
    { "yip", "Copy the paragraph containing the cursor" },
    { "dap", "Delete the current paragraph and its blank-line gap" },
    { "3dd", "Delete this line and the following two lines" },
    { "d$", "Delete from cursor to the end of the line" },
    { "ggVG", "Select entire file in Visual line mode" },
    { "gg=G", "Reindent whole buffer using Vim indentation" },
    { ":%s/foo/bar/gc", "Review each replacement of foo with bar in file" },
    { "A; <Esc>", "Append a semicolon at the end of a line" },
    { "ma ... `a", "Mark a spot, move elsewhere, and jump back exactly" },
    { "/TODO ... n", "Search TODO and step through occurrences" },
    { "cgn ... <Esc> .", "Change one match, then repeat for following matches" },
  } },
  { "REGEX SEARCH EXAMPLES (TYPE / THEN THE PATTERN)", {
    { "/ciw", "Find exact text ciw in this reference" },
    { "/\\v(word|quote)", "Find word OR quote: very magic uses bare |" },
    { "/\\cvisual", "Find visual regardless of capitalization" },
    { "/\\CVisual", "Find Visual with case respected" },
    { "/\\v^\\s*(MARKS|REGISTERS)", "Find indented headings starting MARKS or REGISTERS" },
    { "/\\v\\d{4}-\\d{2}-\\d{2}", "Find a YYYY-MM-DD date in a file" },
    { "/\\v(TODO|FIXME)", "Find TODO or FIXME" },
    { "/\\<word\\>", "Match whole word, not wordy" },
    { "/\\v\\s+", "Find one or more whitespace characters" },
    { "/\\Vfoo.bar", "Find literal foo.bar (dot is not wildcard)" },
    { "/\\vfoo\\zsbar", "Match only bar when immediately after foo" },
    { "n / N", "Next / previous regex match; / starts a new search" },
  } },
}

-- Wide, two-column reference. Lines are composed to fit without sideways scrolling.
local function wrap_words(input, limit)
  local result, current = {}, ""
  limit = math.max(1, limit)
  for token in tostring(input):gmatch("%S+") do
    local word = token
    if #word > limit then
      if current ~= "" then
        result[#result + 1] = current
        current = ""
      end
      while #word > limit do
        result[#result + 1] = word:sub(1, limit)
        word = word:sub(limit + 1)
      end
      current = word
    elseif current == "" then
      current = word
    elseif #current + 1 + #word <= limit then
      current = current .. " " .. word
    else
      result[#result + 1] = current
      current = word
    end
  end
  if current ~= "" or #result == 0 then
    result[#result + 1] = current
  end
  return result
end

local function cell_lines(entry, width)
  if not entry then return {} end
  -- Reserve the same command area in both columns, then wrap descriptions.
  local command_width = math.min(20, math.max(14, math.floor(width * 0.38)))
  command_width = math.min(math.max(command_width, #entry[1]), width - 10)
  local description_width = width - command_width - 3
  local chunks = wrap_words(entry[2], description_width)
  local result = {}
  local label = entry[1]
  if #label > command_width then label = label:sub(1, command_width - 1) .. "~" end
  for i, text in ipairs(chunks) do
    local name = i == 1 and label or ""
    result[i] = string.format("%-" .. command_width .. "s - %s", name, text)
  end
  return result, #label
end

local function padright(text, width)
  return text .. string.rep(" ", math.max(0, width - vim.fn.strdisplaywidth(text)))
end

local function render(width)
  local title = width >= 86
      and " VIM / NEOVIM REFERENCE  |  MOTIONS, COMMANDS, REGEX"
      or " VIM / NEOVIM REFERENCE"
  local tips = width >= 86
      and " j/k: scroll   Space/b: page   / or ?: Vim regex search   n/N: next/prev   Esc/q/Enter: close"
      or width >= 56
        and " j/k: scroll   Space/b: page   /: regex   n/N: results   q/Esc/Enter: close"
        or " j/k: scroll   /: search   q/Esc/Enter: close"
  local lines = { title:sub(1, math.max(1, width - 1)), tips:sub(1, math.max(1, width - 1)), "" }
  local highlights = {}
  local two_columns = width >= 86
  local separator = " | "
  local cell_width = two_columns and math.floor((width - 6) / 2) or width - 2
  local rows_per_group = two_columns and 2 or 1

  for _, group in ipairs(groups) do
    -- Long category titles also wrap within the popup on narrow terminals.
    for _, heading_line in ipairs(wrap_words(group[1], width - 4)) do
      lines[#lines + 1] = "  " .. heading_line
      highlights[#highlights + 1] = { #lines - 1, "Title", 0, -1 }
    end

    local entries = group[2]
    for index = 1, #entries, rows_per_group do
      local left, left_key_length = cell_lines(entries[index], cell_width)
      local right, right_key_length = {}, 0
      if two_columns and entries[index + 1] then
        right, right_key_length = cell_lines(entries[index + 1], cell_width)
      end
      for line_index = 1, math.max(#left, #right) do
        local lhs = left[line_index] or ""
        local rhs = right[line_index] or ""
        local line, second_start
        if two_columns then
          local prefix = " " .. padright(lhs, cell_width) .. separator
          line = prefix .. rhs
          second_start = #prefix
        else
          line = " " .. lhs
        end
        local row_index = #lines
        lines[#lines + 1] = line
        if line_index == 1 then
          highlights[#highlights + 1] = {
            row_index, "Special", 1, 1 + left_key_length,
          }
          if second_start and rhs ~= "" then
            highlights[#highlights + 1] = {
              row_index, "Special", second_start, second_start + right_key_length,
            }
          end
        end
      end
    end
    lines[#lines + 1] = ""
  end
  return lines, highlights
end

local active_win, active_buf = nil, nil
local function dimensions()
  local columns, rows = vim.o.columns, vim.o.lines
  local width, height = columns - 4, rows - 5
  if width < 40 or height < 8 then return nil end
  return { relative = "editor", row = 1, col = 2, width = width, height = height }
end

local function update_buffer(buf, width)
  local lines, highlights = render(width)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, -1, hl[2], hl[1], hl[3], hl[4])
  end
  vim.bo[buf].modifiable = false
end

local function open()
  if active_win and vim.api.nvim_win_is_valid(active_win) then
    vim.api.nvim_set_current_win(active_win)
    return
  end
  local size = dimensions()
  if not size then
    vim.notify("Neovim window is too small for motions reference", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "motions-help"
  update_buffer(buf, size.width)

  local previous_win = vim.api.nvim_get_current_win()
  local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", size, {
    style = "minimal", border = "rounded",
    title = " MOTIONS REFERENCE ", title_pos = "center", zindex = 80,
  }))
  active_win, active_buf = win, buf
  -- Keep the two-column renderer vertically scrollable only.  Neovim permits
  -- horizontal mouse-wheel scrolling in nowrap windows, including trackpads.
  -- Text is already word-wrapped to its column width by render().
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = false
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].scrolloff = 0
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  -- Native / and ? search are Vim regex searches. Highlight only while this
  -- reference is open and restore the editor's previous search state afterward.
  local previous_search = vim.fn.getreg("/")
  local previous_hlsearch = vim.o.hlsearch
  local previous_incsearch = vim.o.incsearch
  vim.o.hlsearch = true
  vim.o.incsearch = true
  local function restore_search()
    vim.fn.setreg("/", previous_search)
    vim.o.hlsearch = previous_hlsearch
    vim.o.incsearch = previous_incsearch
  end

  local restored = false
  local function close()
    if not restored then
      restored = true
      restore_search()
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if active_win == win then active_win, active_buf = nil, nil end
    if vim.api.nvim_win_is_valid(previous_win) then
      vim.api.nvim_set_current_win(previous_win)
    end
  end
  for _, lhs in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", lhs, close, { buffer = buf, nowait = true, silent = true })
  end
  vim.keymap.set("n", "<Space>", "<C-f>", { buffer = buf, silent = true })
  vim.keymap.set("n", "b", "<C-b>", { buffer = buf, silent = true })
  vim.keymap.set("n", "j", "j0", { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "k", "k0", { buffer = buf, nowait = true, silent = true })
  -- Ghostty/macOS can send native horizontal wheel events for trackpad swipes;
  -- some terminals encode these as Shift+vertical wheel instead.  Block both,
  -- but keep normal vertical wheel and j/k/Space/b scrolling untouched.
  for _, lhs in ipairs({
    "h", "l", "<Left>", "<Right>",
    "<ScrollWheelLeft>", "<ScrollWheelRight>",
    "<S-ScrollWheelUp>", "<S-ScrollWheelDown>",
  }) do
    vim.keymap.set("n", lhs, "<Nop>", { buffer = buf, nowait = true, silent = true })
  end
  vim.api.nvim_create_autocmd("WinClosed", {
    once = true,
    pattern = tostring(win),
    callback = function()
      if not restored then
        restored = true
        restore_search()
      end
      if active_win == win then active_win, active_buf = nil, nil end
    end,
  })
end

vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if not (active_win and vim.api.nvim_win_is_valid(active_win)
        and active_buf and vim.api.nvim_buf_is_valid(active_buf)) then
      return
    end
    local size = dimensions()
    if not size then return end
    local cursor = vim.api.nvim_win_get_cursor(active_win)
    vim.api.nvim_win_set_config(active_win, size)
    update_buffer(active_buf, size.width)
    local line_count = vim.api.nvim_buf_line_count(active_buf)
    vim.api.nvim_win_set_cursor(active_win, { math.min(cursor[1], line_count), 0 })
  end,
})

vim.api.nvim_create_user_command("Motions", open, { desc = "Show paged Vim motions and commands" })
vim.keymap.set("n", "<leader>?", open, { desc = "Vim motions reference" })
