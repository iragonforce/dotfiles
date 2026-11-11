local M = {}

function M.reveal(buf, header, width)
  local function center(text)
    local padding = math.max(
      0, math.floor(
        (width - vim.fn.strdisplaywidth(text)) / 2
      )
    )
    return string.rep(" ", padding) .. text
  end

  local function frame(index)
    if not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end

    if vim.bo[buf].filetype ~= "customdashboard"
        or vim.api.nvim_get_current_buf() ~= buf then
      return
    end

    local ok = pcall(function()
      vim.bo[buf].modifiable = true

      -- Header begins at zero-based row 2.
      local row = index + 1
      vim.api.nvim_buf_set_lines(
        buf, row, row + 1, false,
        { center(header[index]) }
      )

      vim.bo[buf].modified = false
    end)

    vim.bo[buf].modifiable = false

    if ok and index < #header then
      vim.defer_fn(function()
        frame(index + 1)
      end, 55)
    end
  end

  vim.defer_fn(function()
    frame(1)
  end, 40)
end

return M
