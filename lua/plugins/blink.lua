-- lua/plugins/blink.lua
return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      local disabled_filetypes = { "markdown", "text", "gitcommit", "copilot-chat" }
      return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
    end,
  },
}
