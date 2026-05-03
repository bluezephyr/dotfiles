-- https://github.com/axkirillov/easypick.nvim
return {
  'axkirillov/easypick.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('easypick').setup({
      pickers = {
        {
          name = "ls",
          command = "ls",
          previewer = require('easypick').previewers.default()
        },
        {
          name = "index",
          command = "fd . --hidden --follow --type file ~/index ",
          previewer = require('easypick').previewers.default()
        },
      }
    })
  end,
}
