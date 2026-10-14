-- lua/plugins/powershell.lua
return {
  {
    "TheLeoP/powershell.nvim",
    ft = "ps1",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
    },
    keys = {
      {
        "<leader>P",
        function()
          require("powershell").toggle_term()
        end,
        ft = "ps1",
        desc = "PS terminal",
      },
      {
        "<leader>E",
        function()
          require("powershell").eval()
        end,
        ft = "ps1",
        desc = "PS eval",
      },
    },
  },
}
