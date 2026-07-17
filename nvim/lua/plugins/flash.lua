--[[
Flash — fast motion/jump by folke.
Replaces native s/S with a two-key label system.
Press `s` to see all visible matches with labels; type the label to jump.
Provides Treesitter-based incremental selection via `<c-space>`.
Triggered on `VeryLazy` (after UI paint).
Keymaps use bare `s`/`S`/`r`/`R` (no `<leader>` prefix).
--]]
return {
  {
    "folke/flash.nvim",
    -- load trigger
    event = "VeryLazy",
    vscode = true,
    opts = {},
    -- jump keymaps
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      -- cmdline toggle + incremental selection
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
      { "<c-space>", mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({
            actions = {
              ["<c-space>"] = "next",
              ["<BS>"] = "prev",
            },
          })
        end, desc = "Treesitter Incremental Selection" },
    },
  },
}
