-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-restore the persistence.nvim session when Neovim starts with no file arguments
-- (e.g. `nvim` or `nvim .`), so you don't have to manually press <leader>qs each time.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
  callback = function()
    -- argc() == 0 means no file/dir args were passed directly to a buffer
    if vim.fn.argc() == 0 then
      require("persistence").load()
    end
  end,
  nested = true, -- allow this autocmd to trigger other autocmds (e.g. BufEnter, FileType)
})

-- Terraform's `terraform validate` (run via nvim-lint's `terraform_validate`)
-- checks the *whole module*, but nvim-lint only applies the resulting
-- diagnostics to the buffer that triggered the lint (the file you just saved).
-- That leaves other already-open .tf/.hcl buffers showing stale (red) errors
-- even after the real problem has been fixed elsewhere in the module.
--
-- To fix this, whenever a terraform/hcl buffer is saved, re-run the linter on
-- every other loaded terraform/hcl buffer as well, so the whole directory's
-- diagnostics get refreshed together.
-- Highlight the currently active window/split with a slightly different
-- background so it's easy to tell at a glance which pane has focus.
-- Works by defining a custom "ActiveWindow" highlight group (derived from
-- Normal, but a touch lighter/darker) and swapping `winhighlight` on
-- WinEnter/WinLeave.
local function set_active_window_highlight()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if not normal.bg then
    return
  end

  -- Nudge the background brightness up or down depending on how dark/light
  -- the current colorscheme's background is, so it works with both.
  local bg = normal.bg
  local r = math.floor(bg / 65536) % 256
  local g = math.floor(bg / 256) % 256
  local b = bg % 256
  local luminance = (r * 299 + g * 587 + b * 114) / 1000
  local delta = luminance < 128 and 12 or -18

  local function clamp(v)
    return math.max(0, math.min(255, v))
  end

  r, g, b = clamp(r + delta), clamp(g + delta), clamp(b + delta)
  local new_bg = r * 65536 + g * 256 + b

  vim.api.nvim_set_hl(0, "ActiveWindow", { bg = new_bg })
end

local active_window_group = vim.api.nvim_create_augroup("active_window_highlight", { clear = true })

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = active_window_group,
  callback = set_active_window_highlight,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = active_window_group,
  callback = function()
    vim.wo.winhighlight = "Normal:ActiveWindow,NormalNC:Normal"
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  group = active_window_group,
  callback = function()
    vim.wo.winhighlight = ""
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("terraform_relint_all", { clear = true }),
  pattern = { "*.tf", "*.tfvars", "*.hcl" },
  callback = function()
    local ok, lint = pcall(require, "lint")
    if not ok then
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local ft = vim.bo[buf].filetype
        if ft == "terraform" or ft == "hcl" or ft == "terraform-vars" then
          -- try_lint accepts an optional bufnr in recent nvim-lint versions;
          -- fall back to switching buffers if the installed version doesn't.
          local lint_ok = pcall(lint.try_lint, nil, { buf = buf })
          if not lint_ok then
            vim.api.nvim_buf_call(buf, function()
              pcall(lint.try_lint)
            end)
          end
        end
      end
    end
  end,
})

