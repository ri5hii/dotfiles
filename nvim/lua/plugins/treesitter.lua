--[[
nvim-treesitter — parser-based syntax highlighting, code navigation, and text objects.
Parsers are auto-compiled on first Neovim run (requires a C compiler).
Covered languages:
  Go suite: go, gomod, gosum.
  Python, Java.
  Web: astro, html, css, javascript, typescript, tsx.
  Data/format: json, markdown, markdown_inline, gitcommit.
  Editor: lua, vim, regex, bash.
--]]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- parsers: languages + web
      ensure_installed = {
        "go",
        "gomod",
        "gosum",
        "python",
        "java",
        "astro",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "markdown",
        "markdown_inline",
        "gitcommit",
        "lua",
        "vim",
        "regex",
        "bash",
      },
    },
  },
}
