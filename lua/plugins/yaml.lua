return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.yamlls = opts.servers.yamlls or {}
      opts.servers.yamlls.settings = {
        yaml = {
          schemaStore = { enable = false, url = "" },
          schemas = {
            ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
              "azure-pipelines.yml",
              "azure-pipelines*.yml",
              "**/pipelines/*.yml",
            },
          },
          validate = true,
          hover = true,
          completion = true,
          format = {
            enable = false, -- formatting handled by yamlfmt via conform, not yamlls
          },
        },
      }
      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "yamlfmt" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "yamlfmt", "yaml-language-server" },
    },
  },
}
