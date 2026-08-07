-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Allow overrides
vim.o.exrc = true
vim.o.secure = true -- still requires manual trust confirmation per file, safer default

-- Use the PowerShell 7 commandline
vim.o.shell = "pwsh"
vim.o.shellcmdflag = "-NoLogo -ExecutionPolicy RemoteSigned -Command"

-- Set the scroll to be centre of the screen when moving up and down
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- Wrapping: wrap long lines at word boundaries, keep indentation
vim.o.wrap = true
vim.o.linebreak = true
vim.o.breakindent = true
vim.o.showbreak = "↪ "
vim.o.textwidth = 0
vim.o.wrapmargin = 0
