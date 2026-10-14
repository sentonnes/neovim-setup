-- lua/plugins/json.lua
return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        json = { "prettier" },
        jsonc = { "prettier" },
        json5 = { "prettier" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "prettier" },
    },
  },
}
