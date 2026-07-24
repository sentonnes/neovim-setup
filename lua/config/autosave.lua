-- autosave on useful events, skip special buffers/filetypes
local M = {}

local excluded_filetypes = {
  "gitcommit",
  "gitrebase",
  "help",
  "fzf",
  "vimfiler",
  "NvimTree",
  "toggleterm",
}

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave" }, {
  pattern = "*",
  callback = function()
    if not vim.bo.modifiable or not vim.bo.modified then
      return
    end
    if vim.fn.expand("%") == "" then
      return
    end -- unnamed buffer
    for _, ft in ipairs(excluded_filetypes) do
      if vim.bo.filetype == ft then
        return
      end
    end
    -- use update to write only if modified, silent to avoid messages
    vim.cmd("silent! update")
  end,
})

return M
