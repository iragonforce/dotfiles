-- Purpose: automatically start SBCL and connect Nvlime when
-- opening a Common Lisp source file.
-- Input: FileType=lisp.
-- Output: one SBCL/Nvlime server per Neovim instance.
-- Does not create a system daemon or modify Lisp source files.

local starting = false

local group = vim.api.nvim_create_augroup(
  "NvlimeSBCLAutostart",
  { clear = true }
)

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "lisp",

  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then return end
    if starting then return end
    if vim.fn.executable("sbcl") ~= 1 then
      vim.notify("SBCL not found", vim.log.levels.ERROR)
      return
    end

    vim.defer_fn(function()
      if starting then return end

      -- Do not launch a duplicate Nvlime-managed server.
      local servers = vim.g.nvlime_servers or {}
      if next(servers) ~= nil then return end

      -- A manually connected backend also counts.
      local ok, conn = pcall(
        vim.fn["nvlime#connection#Get"], true
      )

      if ok and conn ~= nil and conn ~= vim.NIL then
        return
      end

      starting = true

      vim.notify(
        "Nvlime: starting SBCL and connecting...",
        vim.log.levels.INFO
      )

      local success, err = pcall(
        vim.fn["nvlime#server#New"],
        true,  -- Auto-connect when ready
        false  -- Use Nvlime's server-output window
      )

      starting = false

      if not success then
        vim.notify(
          "Nvlime SBCL startup failed: " .. tostring(err),
          vim.log.levels.ERROR
        )
      end
    end, 150)
  end,
})
