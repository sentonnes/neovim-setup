-- lua/plugins/snacks.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      bigfile = {
        enabled = true,
        size = 10 * 1024 * 1024, -- 10 MB (default is 1.5 MB)
        line_length = 100000, -- average chars per line; minified JSON is one long line (default is 1000)
      },
    },
  },
}
