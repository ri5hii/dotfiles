--[[
which-key.nvim — popup that shows pending keybindings as you type by folke.
Uses the `helix` preset (no leading space to trigger).
Organises every `<leader>` prefix into named groups visible when you press `<leader>` and wait.
Triggered on `VeryLazy`.
Keymap groups: `<leader>` submenus for tabs, code, debug, file, git, hunks, quit, search, ui, diagnostics.
Expanded groups: `<leader>b` (buffers), `<leader>w` (windows).
Extended keymaps: `<leader>?` shows buffer keymaps, `<c-w><space>` enters window hydra mode.
--]]
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    opts = {
      -- preset + defaults
      preset = "helix",
      defaults = {},
      -- <leader> group spec
      spec = {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "tabs" },
          { "<leader>c", group = "code" },
          { "<leader>d", group = "debug" },
          { "<leader>dp", group = "profiler" },
          { "<leader>f", group = "file/find" },
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
          { "<leader>q", group = "quit/session" },
          { "<leader>s", group = "search" },
          { "<leader>u", group = "ui" },
          { "<leader>x", group = "diagnostics/quickfix" },
          { "[", group = "prev" },
          { "]", group = "next" },
          { "g", group = "goto" },
          { "gs", group = "surround" },
          { "z", group = "fold" },
          -- group expansions (buffer / window)
          {
            "<leader>b",
            group = "buffer",
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          {
            "<leader>w",
            group = "windows",
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          { "gx", desc = "Open with system app" },
        },
      },
    },
    -- standalone keymaps
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
    -- setup with deprecation guard
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      if not vim.tbl_isempty(opts.defaults) then
        LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
        wk.register(opts.defaults)
      end
    end,
  },
}
