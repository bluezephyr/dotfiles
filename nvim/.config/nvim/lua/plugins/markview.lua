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

-- Hybrid mode shows the cursor line raw, so syntax hidden by the preview can be
-- seen while moving and yanking. These motions switch it on (, and ` toggle
-- it) and Escape switches it off, so the full preview is the resting state.
local HYBRID_KEYS = { "w", "W", "b", "B", "e", "E", "ge", "gE", "f", "F", "t", "T", ";", "y" }

local function hybrid_keymaps(buf)
  local function map(modes, lhs, rhs, desc, expr)
    vim.keymap.set(modes, lhs, rhs, { buffer = buf, desc = desc, expr = expr })
  end
  -- Runs a Markview command, then the key itself. The command consumes the
  -- count and register, so they are restored.
  local function with(command, key)
    return function()
      local count = vim.v.count > 0 and tostring(vim.v.count) or ""
      local register = vim.v.register ~= '"' and '"' .. vim.v.register or ""
      return "<cmd>Markview " .. command .. "<cr>" .. register .. count .. key
    end
  end

  for _, key in ipairs(HYBRID_KEYS) do
    map("n", key, with("hybridEnable", key), "Show line raw and " .. key, true)
  end
  map("n", ",", with("hybridToggle", ","), "Toggle raw line and ,", true)
  map("n", "`", "<cmd>Markview hybridToggle<cr>", "Toggle raw line")
  map({ "n", "i" }, "<esc>", "<esc><cmd>Markview hybridDisable<cr><cmd>noh<cr>",
    "Escape, clear search and render line")
  map({ "x", "s", "o" }, "<esc>", "<esc><cmd>Markview hybridDisable<cr>",
    "Escape and render line")
  -- <C-c> to cancel: an <Esc> sent by a mapping runs the command line instead.
  map("c", "<esc>", "<C-c><cmd>Markview hybridDisable<cr>", "Cancel command and render line")
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
      -- Normal mode starts rendered; hybrid can reveal the current line.
      -- Visual, insert and search stay raw (not listed). Rendering during a
      -- search hides IncSearch's current match. 'no' is hybrid too, or y
      -- would redraw the revealed line while waiting for its motion.
      modes = { 'n', 'no' },
      hybrid_modes = { 'n', 'no' },
      enable_hybrid_mode = false,
      linewise_hybrid_mode = true,
      edit_range = { 0, 0 },
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
    -- Markview's default mode-change callback reveals the cursor line in every
    -- hybrid mode, ignoring whether the buffer has hybrid switched on.
    local default = require("markview.spec").default.preview.callbacks
    opts.preview.callbacks = {
      on_mode_change = function(buffer, wins, mode)
        default.on_mode_change(buffer, wins, mode)
        local state = require("markview.state").get_buffer_state(buffer, false)
        local previewing = require("markview.actions").in_preview_mode(mode)
        if state and not state.hybrid_mode and previewing then
          default.on_hybrid_disable(buffer, wins)
        end
      end,
    }
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
        hybrid_keymaps(args.buf)
      end,
    })
  end,
}
