-- https://github.com/nvim-treesitter/nvim-treesitter
return {
  -- Highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    lazy = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "c", "lua", "rust", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
        ignore_install = { "help" },
        sync_install = false,
        modules = {},
        auto_install = false,
        highlight = {
          enable = true,
        }
      }
    end,
  }
}
