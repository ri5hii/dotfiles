--[[
  lua/config/       → options, keymaps, autocmds, lazy
  lua/plugins/      → per-plugin/concern config files
    core.lua        → LazyVim base colorscheme/news
    go.lua          → gopls settings
    python.lua      → ruff LSP + venv-selector
    java.lua        → jdtls
    mason.lua       → external tool installer
    conform.lua     → formatter runners
    treesitter.lua  → syntax highlighting parsers
    snacks.lua      → picker/explorer/notifier/indent/scroll
    *.lua           → bufferline, flash, gitsigns, lualine, etc
--]]

require("config.lazy")
