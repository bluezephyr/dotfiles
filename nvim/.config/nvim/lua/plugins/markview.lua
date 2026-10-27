-- https://github.com/OXY2DEV/markview.nvim
-- Alternative plugin: https://github.com/MeanderingProgrammer/render-markdown.nvim
return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Recommended

  dependencies = {
    -- "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },

  opts = {
    preview = {
      icon_provider = 'mini',
      -- Not 'c': rendering during a search hides IncSearch's current match.
      modes = { 'n', 'no', 'i' },
      hybrid_modes = { 'n', 'i' },
    },
    markdown = {
      headings = {
        heading_1 = { hl = "@markup.heading.1.markdown" },
        heading_2 = { hl = "@markup.heading.2.markdown" },
        heading_3 = { hl = "@markup.heading.3.markdown" },
        heading_4 = { hl = "@markup.heading.4.markdown" },
        heading_5 = { hl = "@markup.heading.5.markdown" },
        heading_6 = { hl = "@markup.heading.6.markdown" },
        setext_1 = { hl = "@markup.heading.1.markdown" },
        setext_2 = { hl = "@markup.heading.2.markdown" },
      },
    },
  },
}
