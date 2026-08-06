-- lua/plugins/blink.lua
return {
  "saghen/blink.cmp",
  opts = {
    enabled = function()
      local disabled_filetypes = { "markdown", "text", "gitcommit" }
      return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
    end,
    sources = {
      per_filetype = {
        codecompanion = { "codecompanion" },
      },
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
