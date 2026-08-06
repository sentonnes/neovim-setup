return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    { "<C-a>", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion Actions" },
    { "<leader>a", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle CodeCompanion Chat" },
    { "ga", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to CodeCompanion Chat" },
  },
  opts = {
    interactions = {
      chat = {
        adapter = { name = "copilot", model = "claude-sonnet-5" },
      },
      inline = {
        adapter = { name = "copilot", model = "claude-sonnet-5" },
      },
      agent = {
        adapter = { name = "copilot", model = "claude-sonnet-5" },
      },
    },
    completion = {
      blink = { enabled = true },
    },
  },
}
