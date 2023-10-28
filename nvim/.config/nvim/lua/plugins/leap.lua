-- https://github.com/ggandor/leap.nvim
return {
  'ggandor/leap.nvim',
  config = function()
    require("leap").set_default_keymaps()
    vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
  end
}
