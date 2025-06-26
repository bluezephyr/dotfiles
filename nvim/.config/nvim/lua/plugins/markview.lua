-- https://github.com/OXY2DEV/markview.nvim
-- Alternative plugin: https://github.com/MeanderingProgrammer/render-markdown.nvim
return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Recommended

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },

  -- Workaround for issue https://github.com/OXY2DEV/markview.nvim/issues/365
  config = function()
    require("markview").setup({
      experimental = {
        check_rtp_message = false,
      },
    })
  end,
}
