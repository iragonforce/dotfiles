local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("PortableDotfilesQuit", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].filetype == "customdashboard" then vim.opt.laststatus = 0 end
    end,
  })
end

return M
