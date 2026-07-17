--[[
snacks.nvim — UI suite replacement by folke.
Modules:
  picker   — file/tag/grep picker (replaces telescope / fzf-lua)
  explorer — file tree sidebar (replaces neo-tree / nvim-tree)
  notifier — unified message popup (replaces noice messages)
  indent   — indent line guides
  scroll   — smooth scrolling / cursor animation
These five modules are independent; others (dashboard, image, bigfile, gitbrowse, etc.)
remain lazy-loaded and are not pre-enabled here.
Colorscheme picker (`leader uC`) persists selection to `config/colorscheme.lua`.
--]]
return {
  {
    "folke/snacks.nvim",
    opts = {
      -- picker: file finder (replaces telescope / fzf-lua)
      picker = {
        enabled = true,
        formatters = {
          file = { truncate = 80 },
        },
        ignored = true,
        hidden = true,
        -- colorschemes: filter to .lua only (removes .vim duplicates/wrappers), persist on confirm
        sources = {
          colorschemes = {
            finder = function()
              local items = {}
              local rtp = vim.o.runtimepath
              if package.loaded.lazy then
                rtp = rtp .. "," .. table.concat(require("lazy.core.util").get_unloaded_rtp(""), ",")
              end
              -- skip base names that have flavor variants (mocha, moon, etc.)
              local skip_base = { ["catppuccin"] = true, ["tokyonight"] = true, ["rose-pine"] = true }
              local seen = {}
              for _, file in ipairs(vim.fn.globpath(rtp, "colors/*.lua", false, true)) do
                local name = vim.fn.fnamemodify(file, ":t:r")
                if not seen[name] and not skip_base[name] then
                  seen[name] = true
                  items[#items + 1] = { text = name, file = file }
                end
              end
              return items
            end,
            confirm = function(picker, item)
              picker:close()
              if item then
                picker.preview.state.colorscheme = nil
                vim.schedule(function()
                  vim.cmd("colorscheme " .. item.text)
                  -- persist: write selected theme to lua/config/colorscheme.lua
                  local path = vim.fn.stdpath("config") .. "/lua/config/colorscheme.lua"
                  local f = io.open(path, "w")
                  if f then
                    f:write('return "' .. item.text .. '"\n')
                    f:close()
                  end
                end)
              end
            end,
          },
        },
      },
      -- explorer: file tree sidebar (replaces neo-tree / nvim-tree)
      explorer = {
        files = {
          ignored = true,
          hidden = true,
        },
      },
      -- notifier: unified message popup (replaces noice)
      notifier = { enabled = true },
      -- indent: line guides
      indent = { enabled = true },
      -- scroll: smooth scrolling
      scroll = { enabled = true },
    },
  },
}
