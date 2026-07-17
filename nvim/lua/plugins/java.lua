--[[
Java support — Eclipse JDTLS via nvim-jdtls (managed by nvim-lspconfig).
Installed by mason-lspconfig from opts.servers.jdtls below.
--]]
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {},
      },
    },
  },
}
