--[[
Python support — ruff (LSP + formatter) via nvim-lspconfig,
plus venv-selector.nvim for Virtualenv/conda/pipenv switching.
Use `:VenvSelect` to pick the Python environment for ruff.
ruff is auto-installed by mason.nvim and mason-lspconfig.
--]]
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- LSP servers
      servers = {
        ruff = {},
      },
    },
  },
  -- venv-selector: switch Python virtualenv interactively
  {
    "linux-cultist/venv-selector.nvim",
    opts = {},
  },
}
