-- Adds Copilot credit usage ($) to LazyVim's lualine
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    local usage = require("config.copilot_usage")
    usage.setup()
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}
    table.insert(opts.sections.lualine_x, 1, {
      usage.status,
      cond = function()
        return usage.status() ~= ""
      end,
    })
  end,
}
