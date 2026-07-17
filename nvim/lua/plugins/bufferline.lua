--[[
bufferline.nvim — tab bar with filetype icons by akinsho.
Provides buffer-level tabs at the top of each Neovim window.
Buffer keys: `<leader>bp` (pin), `<leader>bP` / `<leader>br` / `<leader>bl` (close).
Navigation: `<S-h>` / `<S-l>` or `[b` / `]b` (cycle), `]B` / `[B` (move), `<leader>bj` (pick).
Shows LSP diagnostics as badges and reserves space for neo-tree / snacks layout box.
Requires nvim-tree/nvim-web-devicons for icons.
Triggered on `VeryLazy`.
Key prefixes: `<leader>b` (buffer), `[b` / `]b` (cycle), `<S-h>` / `<S-l>` (cycle).
--]]

--[[
nvim-web-devicons — filetype icons used by bufferline and other plugins.
Provides `get_icon(name, ext, opts)` and `get_icon_by_filetype(filetype, opts)`.
Loaded lazily by bufferline's `get_element_icon` fetcher.
--]]
return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {},
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    -- buffer keymaps
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
      { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
    },
    opts = {
      options = {
        -- close / delete: replaces LazyVim's Snacks.bufdelete
        close_command = function(n) vim.cmd.bdelete({ n, bang = true }) end,
        right_mouse_command = function(n) vim.cmd.bdelete({ n, bang = true }) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        -- diagnostics indicator: shows error + warning counts in the tab
        diagnostics_indicator = function(_, _, diag)
          local icons = { Error = " ", Warn = " ", Hint = " ", Info = " " }
          local ret = (diag.error and icons.Error .. diag.error .. " " or "")
            .. (diag.warning and icons.Warn .. diag.warning or "")
          return vim.trim(ret)
        end,
        -- offsets: reserve top space for neo-tree + snacks layout box
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          {
            filetype = "snacks_layout_box",
          },
        },
        -- icon: defer to nvim-web-devicons by filetype
        get_element_icon = function(opts)
          local icon, _ = require("nvim-web-devicons").get_icon_by_filetype(opts.filetype, { default = false })
          return icon
        end,
      },
    },
    -- setup: re-render on buffer add / delete (fixes stale tabs after session restore)
    config = function(_, opts)
      require("bufferline").setup(opts)
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(require("bufferline").cycle, 1)
          end)
        end,
      })
    end,
  },
}
