--[[
persistence.nvim — auto-save/restore sessions by folke.
Saves your current session (open buffers, windows, layout) in the background.
Restore via `<leader>qs` (last), `<leader>qS` (select), or `<leader>ql` (last session).
`<leader>qd` stops saving for the current session.
Triggered on `BufReadPre`.
Key prefixes: `<leader>q` (quit/session).
--]]
return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    -- session keymaps
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
}
