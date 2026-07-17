--[[
LazyVim — full Neovim distribution by folke.
This file imports LazyVim as the base layer; per-plugin overrides in sibling files take priority.
Effective opts here:
  - colorscheme loaded from `config/colorscheme.lua` (persisted via picker `leader uC`)
  - news popup disabled for both LazyVim and Neovim updates
All other LazyVim plugin defaults continue to load from the import below.
--]]
return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme: load persisted selection from config/colorscheme.lua
      -- written by the Snacks picker confirm hook; falls back to tokyonight
      colorscheme = function()
        local ok, theme = pcall(require, "config.colorscheme")
        vim.cmd.colorscheme(ok and theme or "tokyonight")
      end,
      news = {
        lazyvim = false,
        neovim = false,
      },
    },
  },
}
