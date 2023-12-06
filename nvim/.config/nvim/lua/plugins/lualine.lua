-- See https://github.com/nvim-lualine/lualine.nvim
-- Set lualine as statusline
return {
  'nvim-lualine/lualine.nvim',
  -- See `:help lualine.txt`
  opts = {
    options = {
      icons_enabled = false,
      theme = 'onedark',
      component_separators = '|',
      section_separators = '',
    },
    sections = {
      lualine_c = { { 'filename', path = 3 } }
    },
  },
}
