return {
  -- https://github.com/echasnovski/mini.nvim/tree/main
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup()
      require('mini.surround').setup()
      require('mini.bracketed').setup()
      require('mini.basics').setup()
      require('mini.operators').setup()
      local statusline = require('mini.statusline')
      statusline.setup { use_icons = true }
    end
  },
}
