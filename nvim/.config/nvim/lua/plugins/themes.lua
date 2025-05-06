return {
  {
    -- Theme inspired by Atom
    -- https://github.com/navarasu/onedark.nvim
    'navarasu/onedark.nvim',
    priority = 1000,

    config = function()
      require('onedark').setup {
        style = 'dark'
      }

      -- Enable theme
      require('onedark').load()
    end
  },
  {
    -- Theme catppuccin
    -- https://github.com/catppuccin/nvim
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    config = function()
      require('catppuccin').setup({})
    end,
  }
}
