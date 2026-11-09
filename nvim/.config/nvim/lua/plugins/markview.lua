-- https://github.com/OXY2DEV/markview.nvim
-- Alternative plugin: https://github.com/MeanderingProgrammer/render-markdown.nvim

-- The kinds of link markview draws, each with an icon and colour per site.
local LINK_KINDS = { "block_references", "emails", "embed_files", "hyperlinks", "internal_links", "uri_autolinks" }

-- Every link alike, as italic text in the theme's link blue (NoteLink, set in
-- config.options) without an icon: markview's own colours and icons vary by
-- site and kind, so links don't read as one thing.
local function plain_links()
  local defaults = require("markview.config.markdown_inline")
  local out = {}
  for _, kind in ipairs(LINK_KINDS) do
    out[kind] = {}
    for pattern, entry in pairs(defaults[kind]) do
      if type(entry) == "table" then
        out[kind][pattern] = { icon = "", hl = "NoteLink", file_hl = entry.file_hl and "NoteLink" }
      end
    end
  end
  return out
end

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

  config = function(_, opts)
    opts.markdown_inline = plain_links()
    require("markview").setup(opts)
  end,
}
