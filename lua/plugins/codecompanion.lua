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
        adapter = { name = "copilot", model = "claude-opus-5.5" },
      },
      inline = {
        adapter = { name = "copilot", model = "claude-opus-5.5" },
      },
      agent = {
        adapter = { name = "copilot", model = "claude-opus-5.5" },
      },
    },
    completion = {
      blink = { enabled = true },
    },
    mcp = {
      servers = {
        github = function()
          local token = vim.trim(vim.fn.system({ "gh", "auth", "token" }))
          if vim.v.shell_error ~= 0 or token == "" then
            token = os.getenv("GITHUB_TOKEN")
          end
          return {
            cmd = {
              "docker", "run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
              "ghcr.io/github/github-mcp-server",
            },
            env = { GITHUB_PERSONAL_ACCESS_TOKEN = token },
          }
        end,
      },
      opts = {
        default_servers = { "github" },
      },
    },
  },
}
