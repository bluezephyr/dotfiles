local options = {
  breakindent = true,                      -- indent text after linebreaksop
  clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
  cmdheight = 1,                           -- more space in the neovim command line for displaying messages
  completeopt = { "menuone", "noselect" }, -- mostly just for cmp
  conceallevel = 0,                        -- so that `` is visible in markdown files
  confirm = true,                          -- raise dialog instead of failing operation
  fileencoding = "utf-8",                  -- the encoding written to a file
  guifont = "monospace:h17",               -- the font used in graphical neovim applications
  hlsearch = true,                         -- highlight all matches on previous search pattern
  ignorecase = true,                       -- ignore case in search patterns
  list = true,
  mouse = "a",                             -- allow the mouse to be used in neovim
  number = true,                           -- set numbered lines
  numberwidth = 4,                         -- set number column width to 4
  pumheight = 10,                          -- pop up menu height
  relativenumber = true,                   -- set relative numbered lines
  scrolloff = 15,
  showmode = true,                         -- we don't need to see things like -- INSERT -- anymore
  showtabline = 2,                         -- always show tabs
  sidescrolloff = 8,
  signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
  spelllang = "en,sv",                     -- spell check English and Swedish (see <leader>tc)
  splitbelow = true,                       -- force all horizontal splits to go below current window
  splitright = true,                       -- force all vertical splits to go to the right of current window

  swapfile = false,                        -- creates a swapfile
  undofile = true,                         -- enable persistent undo, uses default undodir
  writebackup = false,                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  backup = false,                          -- creates a backup file

  -- Tab / Indentation
  shiftround = true,                       -- round indent to multiple of 'shiftwidth' tabstop = 4,
  shiftwidth = 4,                          -- the number of spaces inserted for each indentation
  tabstop = 4,
  softtabstop = 4,
  expandtab = true,                        -- convert tabs to spaces
  smartcase = true,                        -- smart case
  smartindent = true,                      -- make indenting smarter again
  wrap = false,                            -- display lines as one long line

  -- Visual
  termguicolors = true,                    -- set term gui colors (most terminals support this)
  textwidth = 90,
  colorcolumn = "90",
  title = true,
  cursorline = true,                       -- highlight the current line
  winborder = "rounded",                   -- frame every float that does not bring its own border

  timeoutlen = 500,                        -- time to wait for a mapped sequence to complete (in milliseconds)
  timeout = true,
  updatetime = 250,                        -- faster completion (4000ms default)
}

vim.opt.shortmess:append "c"
vim.opt.listchars = { tab = '▸ ', trail = '·' }

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work

-- Floats must stand out from the buffer: a theme's own NormalFloat often sits a
-- shade from Normal and collides with CursorLine. Derived, so a colorscheme
-- switch keeps the contrast instead of the previous theme's colors.
local FLOAT_CONTRAST = 0.30

-- Moves one channel toward black on a dark background, toward white on a light one.
local function shift_channel(value, lighten)
  local target = lighten and 255 or 0
  return math.floor(value + (target - value) * FLOAT_CONTRAST + 0.5)
end

local function shift_color(color, lighten)
  local r = shift_channel(math.floor(color / 65536) % 256, lighten)
  local g = shift_channel(math.floor(color / 256) % 256, lighten)
  local b = shift_channel(color % 256, lighten)
  return r * 65536 + g * 256 + b
end

local function style_floats()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  if not normal.bg then
    return
  end
  -- Function carries the theme's blue accent, brighter than the Comment grey
  -- most themes give FloatBorder.
  local accent = vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
  local bg = shift_color(normal.bg, vim.o.background == "light")
  vim.api.nvim_set_hl(0, "NormalFloat", { fg = normal.fg, bg = bg })
  vim.api.nvim_set_hl(0, "FloatBorder", { fg = accent, bg = bg })
  vim.api.nvim_set_hl(0, "FloatTitle", { fg = accent, bg = bg, bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = style_floats })
style_floats()
