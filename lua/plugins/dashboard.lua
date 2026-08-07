-- Override the LazyVim/snacks.nvim dashboard ASCII art header
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [[
███████╗██████╗       ██╗    
██╔════╝██╔══██╗      ██║    
███████╗██████╔╝      ██║    
╚════██║██╔══██╗ ██   ██║    
███████║██║  ██║ ╚█████╔╝    
╚══════╝╚═╝  ╚═╝  ╚════╝ ames
        ]],
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#006400", bold = true })
  end,
}
