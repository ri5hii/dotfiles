--[[
colorscheme.lua — bundled colorscheme plugin specs.
All themes are lazy-loaded; they load on demand when selected via the picker
(`leader uC`) or when `:colorscheme <name>` is invoked.
The Snacks picker discovers themes by globbing `runtimepath` for `colors/*`,
so any plugin that installs a `colors/<name>.lua` appears automatically.
The selected theme persists across restarts via `lua/config/colorscheme.lua`.
--]]
return {

  -- tokyonight — default theme by folke, moon variant
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "moon" },
  },

  -- catppuccin — pastel palette with extensive plugin integrations
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        mini = true,
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        snacks = true,
        telescope = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    -- catppuccin bufferline integration (conditional on active theme)
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.special.bufferline").get_theme()
          end
        end,
      },
    },
  },

  -- gruvbox — retro groove colorscheme by ellisonleao
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {},
  },

  -- kanagawa — inspired by the colors of Kanagawa wave by rebelot
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {},
  },

  -- dracula — dark theme with vibrant accents by Mofiqul
  {
    "Mofiqul/dracula.nvim",
    lazy = true,
    opts = {},
  },

  -- rose-pine — all natural pine, faux fur and a bit of soho vibes
  {
    "rose-pine/neovim",
    lazy = true,
    name = "rose-pine",
    opts = {},
  },

  -- nord — arctic, north-bluish clean and elegant theme
  {
    "shaunsingh/nord.nvim",
    lazy = true,
    opts = {},
  },

  -- nightfox — highly customizable theme pack by EdenEast
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
    opts = {},
  },
}
