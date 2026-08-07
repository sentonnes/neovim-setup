-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move by visual line instead of logical line (useful with wrap enabled)
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
