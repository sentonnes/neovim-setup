# 💤 My Neovim Config

A personal [LazyVim](https://github.com/LazyVim/LazyVim)-based Neovim configuration, tailored on top of the LazyVim starter template.

See the [LazyVim documentation](https://lazyvim.github.io/installation) for general setup and keymap references not covered here.

## ✨ Highlights

- **Colorscheme:** `tokyonight-day`
- **Custom dashboard header** with green ASCII art branding
- **AI assistance** via [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) using GitHub Copilot (`claude-sonnet-5`) for chat, inline edits, and agentic actions
- **Git workflow** via [neogit](https://github.com/NeogitOrg/neogit) with `diffview.nvim` integration
- **Completion** via [blink.cmp](https://github.com/saghen/blink.cmp), disabled in `markdown`, `text`, and `gitcommit` buffers, with a dedicated source for CodeCompanion chat
- **YAML tooling:** `yamlls` + `yamlfmt` (via conform.nvim), with schema support for Azure Pipelines files
- **Autosave:** buffers are silently written on `FocusLost`, `BufLeave`, and `InsertLeave`, skipping special/unnamed buffers and excluded filetypes (`gitcommit`, `gitrebase`, `help`, `fzf`, `vimfiler`, `NvimTree`, `toggleterm`)
- **`:Scratch` command** to open a throwaway scratch buffer with no save prompt
- **speedtyper.nvim** for typing practice, loaded eagerly

## ⌨️ Key Custom Keymaps

| Mode | Keymap | Action |
| --- | --- | --- |
| `n`, `v` | `<C-a>` | Open CodeCompanion Actions |
| `n`, `v` | `<leader>a` | Toggle CodeCompanion Chat |
| `v` | `ga` | Add selection to CodeCompanion Chat |
| `n` | `<leader>gn` | Open Neogit |

See [`lua/config/keymaps.lua`](lua/config/keymaps.lua) for the full list of custom keymaps.

## 📁 Structure

```
├── lua
│   ├── config
│   │   ├── autocmds.lua   -- custom autocommands
│   │   ├── autosave.lua   -- silent autosave on focus/buffer change
│   │   ├── keymaps.lua    -- custom keymaps
│   │   ├── lazy.lua       -- lazy.nvim bootstrap/setup
│   │   ├── options.lua    -- custom options
│   │   └── scratch.lua    -- :Scratch command
│   └── plugins
│       ├── blink.lua          -- blink.cmp completion config
│       ├── codecompanion.lua  -- AI chat/inline/agent config (Copilot)
│       ├── colorscheme.lua    -- tokyonight-day colorscheme
│       ├── dashboard.lua      -- custom dashboard ASCII header
│       ├── neogit.lua         -- Neogit + diffview
│       ├── speedtyper.lua     -- typing practice plugin
│       └── yaml.lua           -- yamlls/yamlfmt/mason YAML setup
└── init.lua
```

## 🚀 Installation

1. Back up any existing Neovim config (`~/.config/nvim`, or `%LOCALAPPDATA%\nvim` on Windows).
2. Clone this repo into that location.
3. Launch `nvim` and let `lazy.nvim` install the plugins.
4. Ensure GitHub Copilot is authenticated for `codecompanion.nvim` to work (`:Copilot auth` if using a Copilot plugin, or follow the [codecompanion.nvim Copilot setup](https://codecompanion.olimorris.dev)).

