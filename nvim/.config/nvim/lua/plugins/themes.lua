return {
  {
    -- Theme inspired by Atom
    -- https://github.com/navarasu/onedark.nvim
    'navarasu/onedark.nvim',
    priority = 1000,

    -- lua/colorscheme picks which one actually loads.
    opts = {
      style = 'dark',
    },
  },
  {
    -- Theme catppuccin
    -- https://github.com/catppuccin/nvim
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    opts = {},
  }
}
