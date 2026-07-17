--[[
mason.nvim — external tool installer by williamboman.
Ensures_installed lists LSP servers explicitly for GitHub-visibility,
even though mason-lspconfig auto-installs them from lspconfig.opts.servers.
--]]
return {
  {
    "mason-org/mason.nvim",
    opts = {
      -- Explicit ensure list (redundant but visible in dotfiles)
      ensure_installed = {
        "gopls",
        "jdtls",
        "ruff",
        "lua-language-server",
        "astro-language-server",
        "vtsls"
      },
    },
  },
}
