-- https://github.com/OXY2DEV/markview.nvim
-- Alternative plugin: https://github.com/MeanderingProgrammer/render-markdown.nvim

-- The kinds of link markview draws, each with an icon and colour per site.
local LINK_KINDS = { "block_references", "emails", "embed_files", "hyperlinks", "internal_links", "uri_autolinks" }

-- Every link alike, as italic text in the link colour (NoteLink, set in
-- config.markdown_colours) without an icon: markview's own colours and icons
-- vary by site and kind, so links don't read as one thing.
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
      -- Rendered in normal mode, raw in insert mode (not listed, so markview
      -- clears the preview). Not 'c': rendering during a search hides
      -- IncSearch's current match.
      modes = { 'n', 'no' },
      hybrid_modes = {},
    },
    markdown = {
      headings = {
        -- The same rule before every heading instead of markview's icons, with
        -- no indent per level and no icon in the sign column. "label", not
        -- "icon": with no indent, "icon" draws an icon as wide as the #s over
        -- them and leaves the space after, so h3 got an extra space.
        shift_width = 0,
        heading_1 = { style = "label", hl = "@markup.heading.1.markdown", icon = "━━ ", sign = "" },
        heading_2 = { style = "label", hl = "@markup.heading.2.markdown", icon = "━━ ", sign = "" },
        heading_3 = { style = "label", hl = "@markup.heading.3.markdown", icon = "━━ ", sign = "" },
        heading_4 = { style = "label", hl = "@markup.heading.4.markdown", icon = "━━ ", sign = "" },
        heading_5 = { style = "label", hl = "@markup.heading.5.markdown", icon = "━━ ", sign = "" },
        heading_6 = { style = "label", hl = "@markup.heading.6.markdown", icon = "━━ ", sign = "" },
        setext_1 = { hl = "@markup.heading.1.markdown" },
        setext_2 = { hl = "@markup.heading.2.markdown" },
      },
      -- Every bullet in the same colour (NoteBullet, set in
      -- config.markdown_colours) instead of a different colour per marker:
      -- a chevron for -, a dot for * and + (between • and ● in size; not in
      -- the Nerd Font, so the terminal borrows it from a fallback font).
      list_items = {
        marker_minus = { text = "›", hl = "NoteBullet" },
        marker_plus = { text = "⦁", hl = "NoteBullet" },
        marker_star = { text = "⦁", hl = "NoteBullet" },
        marker_dot = { hl = "NoteBullet" },
        marker_parenthesis = { hl = "NoteBullet" },
      },
    },
  },

  config = function(_, opts)
    opts.markdown_inline = plain_links()
    -- Only the box is coloured: markview tints the whole item by default,
    -- which turns a list of long items into a wall of red. Ticked items fade
    -- (NoteTicked), so the ones left stand out. false, not nil: setup merges
    -- into the defaults, so a missing scope_hl keeps theirs.
    opts.markdown_inline.checkboxes = {
      checked = { text = "󰄵", hl = "NoteChecked", scope_hl = "NoteTicked" },
      unchecked = { text = "󰄱", hl = "NoteBullet", scope_hl = false },
    }
    -- Tags in the colour set in config.markdown_colours, the # shown as a tag
    -- icon and without markview's padding, which made a pill with a background.
    opts.markdown_inline.tags = { default = { hl = "NoteTag", icon = "󰓹 ", padding_left = "", padding_right = "" } }
    require("markview").setup(opts)

    -- Ctrl-x ticks or unticks the line's checkbox (or each selected line's),
    -- adding one to a plain list item. Only [ ] and [x], as the notes use.
    -- Replaces the decrement there, which prose has no use for.
    require("markview.extras.checkboxes").setup({ default = "x", states = { { " ", "x" } } })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function(args)
        vim.keymap.set({ "n", "x" }, "<C-x>", "<cmd>Checkbox toggle<cr>",
          { buffer = args.buf, desc = "zk: Toggle checkbox" })
      end,
    })
  end,
}
