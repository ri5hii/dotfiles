--[[
lualine.nvim — statusline by hoobnobst.
Sections (left to right):
  a = mode (-- INSERT --, etc.)
  b = git branch
  c = project root name, LSP diagnostics, filetype icon, truncated file path
  x = snacks profiler, noice cmdline/mode, DAP status, lazy updates, git diff
  y = progress (line/col), location percentage
  z = current time (24-hour)
Conditional integrations: noice, DAP, lazy.status, snacks profiler (no-op when absent).
Trouble symbols appended to `lualine_c` when `vim.g.trouble_lualine` is set.
Triggered on `VeryLazy`.
--]]
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local lualine_require = require("lualine_require")
      lualine_require.require = require

      -- icon tables (inlined: replaces LazyVim.config.icons.*)
      local icons = {
        diagnostics = {
          Error = " ",
          Warn = " ",
          Info = " ",
          Hint = " ",
        },
        git = {
          added = " ",
          modified = " ",
          removed = " ",
        },
      }

      local opts = {
        -- options: theme, globalstatus, disabled filetype list
        options = {
          theme = "auto",
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            -- project root: first parent with .git, package.json, go.mod, etc.
            function()
              local root = vim.fs.root(0, { ".git", "lua", "go.mod", "package.json", "pyproject.toml", "Cargo.toml" })
              return root and vim.fn.fnamemodify(root, ":t") .. " " or ""
            end,
            -- diagnostics with icons
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            -- filetype icon + truncated path
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            function()
              local path = vim.fn.expand("%:.")
              if path == "" then
                return ""
              end
              local root = vim.fs.root(0, { ".git", "lua", "go.mod", "package.json", "pyproject.toml", "Cargo.toml" })
              if root then
                local rel = vim.fn.fnamemodify(path, ":~:" .. root)
                return rel
              end
              return path
            end,
          },
          lualine_x = {
            -- snacks profiler (no-op if not loaded)
            function()
              local ok, prof = pcall(require, "snacks.profiler")
              if ok and prof and prof.status then
                return prof.status()
              end
              return ""
            end,
            -- noice cmdline status (cond-gated)
            {
              function()
                return require("noice").api.status.command.get()
              end,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.command.has()
              end,
              color = function()
                local fg = vim.api.nvim_get_hl(0, { name = "Statement" }).fg
                return fg and { fg = string.format("#%06x", fg) } or {}
              end,
            },
            -- noice mode status (cond-gated)
            {
              function()
                return require("noice").api.status.mode.get()
              end,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = function()
                local fg = vim.api.nvim_get_hl(0, { name = "Constant" }).fg
                return fg and { fg = string.format("#%06x", fg) } or {}
              end,
            },
            -- DAP status (cond-gated)
            {
              function()
                return " " .. require("dap").status()
              end,
              cond = function()
                return package.loaded["dap"] and require("dap").status() ~= ""
              end,
              color = function()
                local fg = vim.api.nvim_get_hl(0, { name = "Debug" }).fg
                return fg and { fg = string.format("#%06x", fg) } or {}
              end,
            },
            -- lazy plugin updates (cond-gated)
            {
              function()
                return require("lazy.status").updates()
              end,
              cond = function()
                return package.loaded["lazy"] and require("lazy.status").has_updates()
              end,
              color = function()
                local fg = vim.api.nvim_get_hl(0, { name = "Special" }).fg
                return fg and { fg = string.format("#%06x", fg) } or {}
              end,
            },
            -- diff via gitsigns_status_dict (populated by gitsigns.nvim)
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
        -- extensions: auto-skipped if not installed
        extensions = { "neo-tree", "lazy", "fzf" },
      }

      -- trouble symbols: appended to lualine_c when `vim.g.trouble_lualine` is set
      if vim.g.trouble_lualine and pcall(require, "trouble") then
        local trouble = require("trouble")
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end

      return opts
    end,
  },
}
