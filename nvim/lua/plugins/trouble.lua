--[[
trouble.nvim — pretty diagnostics/quickfix/LSP/references list by folke.
Opens in a right-side window.
`<leader>xx` / `<leader>xX` toggles diagnostics (all or buffer).
`<leader>cs` / `<leader>cS` toggles symbols / LSP references.
`<leader>xL` / `<leader>xQ` toggles location / quickfix lists.
`[q` / `]q` jump between items and fall back to native quickfix when Trouble is closed.
Triggered via `:Trouble` command.
Key prefixes: `<leader>x` (diagnostics/quickfix), `<leader>c` (code), `[q` / `]q`.
--]]
return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    -- window placement
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    -- diagnostics + list keymaps
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      -- [q / ]q: jump items in Trouble or fall back to native quickfix
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Previous Trouble/Quickfix Item",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next Trouble/Quickfix Item",
      },
    },
  },
}
