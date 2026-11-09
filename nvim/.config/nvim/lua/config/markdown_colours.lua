-- The colours of markdown, all in one place. Each entry names the theme
-- highlight group whose colour it borrows, so a colorscheme switch keeps the
-- roles (italic is always the theme's string colour, and so on) in that
-- theme's shades. In onedark: String green, Type yellow, Function blue,
-- Keyword purple, Number orange, Constant cyan, Comment grey, @markup.list red.
local COLOURS = {
  -- Many themes colour emphasis like plain text, leaving only the font style,
  -- which is hard to spot.
  italic = "String",
  bold = "Type",
  -- Links as markview draws them (NoteLink), and their raw labels and URLs,
  -- without the underline some themes give URLs.
  link = "Function",
  -- List bullets, numbers and unticked checkbox icons (NoteBullet).
  bullet = "@markup.list",
  -- The icon of ticked checkboxes (NoteChecked), and their text (NoteTicked).
  checked = "String",
  ticked = "Comment",
  -- Tags such as #lore, in italic as markview draws them (NoteTag) and raw.
  tag = "Constant",
  -- One per heading level from h1; the levels past the last take the last.
  -- The theme's own first three (onedark: red, purple, orange), so h4 to h6
  -- stay at h3's instead of starting over.
  headings = { "@markup.heading.1.markdown", "@markup.heading.2.markdown", "@markup.heading.3.markdown" },
}

local style = require("style")

local function fg(group)
  return style.hl(group).fg
end

-- Recolours a heading level, keeping the theme's other attributes such as bold.
-- Markdown headings only, so code is untouched.
local function set_heading(level, colour)
  local name = "@markup.heading." .. level .. ".markdown"
  local hl = style.hl(name)
  hl.fg = colour
  vim.api.nvim_set_hl(0, name, hl)
end

local function apply()
  local link = fg(COLOURS.link)
  for _, lang in ipairs({ "", ".markdown_inline" }) do
    vim.api.nvim_set_hl(0, "@markup.italic" .. lang, { fg = fg(COLOURS.italic), italic = true })
    vim.api.nvim_set_hl(0, "@markup.strong" .. lang, { fg = fg(COLOURS.bold), bold = true })
    vim.api.nvim_set_hl(0, "@markup.link" .. lang, { fg = link })
    vim.api.nvim_set_hl(0, "@markup.link.label" .. lang, { fg = link })
    vim.api.nvim_set_hl(0, "@markup.link.url" .. lang, { fg = link })
  end
  vim.api.nvim_set_hl(0, "NoteLink", { fg = link, italic = true })
  vim.api.nvim_set_hl(0, "NoteBullet", { fg = fg(COLOURS.bullet) })
  vim.api.nvim_set_hl(0, "NoteChecked", { fg = fg(COLOURS.checked) })
  vim.api.nvim_set_hl(0, "NoteTicked", { fg = fg(COLOURS.ticked) })

  local tag = fg(COLOURS.tag)
  vim.api.nvim_set_hl(0, "NoteTag", { fg = tag, italic = true })
  -- zk's language server marks tags as enum members.
  vim.api.nvim_set_hl(0, "@lsp.type.enumMember.markdown", { fg = tag, italic = true })

  -- Resolved before any is set, since they read the heading groups themselves.
  local headings = vim.tbl_map(fg, COLOURS.headings)
  for level = 1, 6 do
    set_heading(level, headings[math.min(level, #headings)])
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = apply })
apply()
