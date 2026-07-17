--[[
Go support — gopls LSP settings via nvim-lspconfig.
Codelenses enabled: run tests, generate code, go:generate, govulncheck, tidy, upgrade, vendor.
Inline hints enabled: assign variable types, composite literal fields/types, constant values, function type params, parameter names, range variable types.
Extra analyses: unusedparams, unusedwrite, useany.
staticcheck integration enabled.
Loads when nvim-lspconfig initializes.
--]]
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              -- codelenses
              codelenses = {
                gc_details = true,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
              },
              -- hints
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
              -- analyses + staticcheck
              analyses = {
                unusedparams = true,
                unusedwrite = true,
                useany = true,
              },
              staticcheck = true,
            },
          },
        },
      },
    },
  },
}
