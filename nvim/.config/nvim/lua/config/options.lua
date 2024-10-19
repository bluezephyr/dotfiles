local options = {
    breakindent = true,                      -- indent text after linebreaks
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
    textwidth = 79,
    colorcolumn = "90",
    title = true,
    cursorline = true,                       -- highlight the current line

    timeoutlen = 500,                        -- time to wait for a mapped sequence to complete (in milliseconds)
    timeout = true,
    updatetime = 250,                        -- faster completion (4000ms default)
}

vim.opt.shortmess:append "c"
vim.opt.listchars = {tab = '▸ ', trail = '·'}

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work
