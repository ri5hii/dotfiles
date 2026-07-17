--[[
conform.nvim — async formatter runner by stevearc.
Runs on save (trigger configured elsewhere via the LazyVim save mechanism).
Each filetype maps to an ordered list of formatters; the first available one is used.
`stop_after_first` causes prettierd to be preferred over prettier for web languages.
--]]
return {
  {
    "stevearc/conform.nvim",
    opts = {
      -- formatters_by_ft: filetype -> ordered formatter list
      formatters_by_ft = {
        go = {},          -- falls through to gopls LSP formatting
        python = { "ruff_format" },
        java = {},        -- falls through to jdtls LSP formatting
        lua = { "stylua" },
        sh = {},          -- falls through to LSP formatting (bashls if active)
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },
}
