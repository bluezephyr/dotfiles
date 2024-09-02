-- https://github.com/petertriho/nvim-scrollbar
return {
  'petertriho/nvim-scrollbar',
  config = function()
    require('scrollbar').setup({
      handle = {
        color = 'Gray',
      }
    })
  end
}
