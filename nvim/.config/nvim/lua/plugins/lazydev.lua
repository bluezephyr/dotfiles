-- lazy.nvim is a modern plugin manager for Neovim.
-- https://github.com/folke/lazydev.nvim
return {
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  -- https://github.com/Bilal2453/luvit-meta
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
}
