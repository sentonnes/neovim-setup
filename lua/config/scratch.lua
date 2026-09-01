-- Scratch buffer: throwaway buffer, not tied to a file, no save prompt
vim.api.nvim_create_user_command("Scratch", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.bo.swapfile = false
end, {})
