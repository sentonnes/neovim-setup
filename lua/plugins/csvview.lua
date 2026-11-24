return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
  keys = {
    { "<leader>cv", "<cmd>CsvViewToggle<cr>", desc = "Toggle CSV view" },
  },
  ---@module "csvview"
  ---@type CsvView.Options
  opts = {
    parser = { comments = { "#", "//" } },
    view = {
      display_mode = "border",
      sticky_header = { enabled = true },
    },
    keymaps = {
      -- Text objects for selecting fields: e.g. `cif` change field, `daf` delete field
      textobject_field_inner = { "if", mode = { "o", "x" } },
      textobject_field_outer = { "af", mode = { "o", "x" } },
      -- Excel-like navigation
      jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
      jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
      jump_next_row = { "<Enter>", mode = { "n", "v" } },
      jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
    },
  },
  config = function(_, opts)
    require("csvview").setup(opts)
    -- Turn the table view on automatically for CSV/TSV buffers
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("CsvViewAuto", { clear = true }),
      pattern = { "csv", "tsv" },
      callback = function(args)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) and not require("csvview").is_enabled(args.buf) then
            require("csvview").enable(args.buf)
          end
        end)
      end,
    })
    -- The plugin loads on the FileType event, so enable the buffer that triggered it
    if vim.tbl_contains({ "csv", "tsv" }, vim.bo.filetype) then
      require("csvview").enable(0)
    end
  end,
}
