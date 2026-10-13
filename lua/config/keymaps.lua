-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move by visual line instead of logical line (useful with wrap enabled)
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Open a scratch buffer (throwaway, no save prompt)
vim.keymap.set("n", "<leader>sc", "<cmd>Scratch<cr>", { desc = "Open Scratch Buffer" })

-- Paste over a visual selection without clobbering the unnamed register
-- (the replaced text goes to the black hole register instead of overwriting your clipboard/yank)
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without overwriting register" })
