return {
  -- https://github.com/akinsho/bufferline.nvim
  'akinsho/bufferline.nvim',
  version = "*",
  dependencies = 'nvim-tree/nvim-web-devicons',

  config = function()
    require("bufferline").setup {}
  end,
}
