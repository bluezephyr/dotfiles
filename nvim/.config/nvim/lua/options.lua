local options = {
    backup = false,                          -- creates a backup file
    breakindent = true,                      -- indent text after linebreaks
    clipboard = "unnamedplus",               -- allows neovim to access the system clipboard
    cmdheight = 1,                           -- more space in the neovim command line for displaying messages
    colorcolumn = "90",
    completeopt = { "menuone", "noselect" }, -- mostly just for cmp
    conceallevel = 0,                        -- so that `` is visible in markdown files
    confirm = true,                          -- raise dialog instead of failing operation
    cursorline = true,                       -- highlight the current line
    expandtab = true,                        -- convert tabs to spaces
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
    shiftround = true,                       -- round indent to multiple of 'shiftwidth' tabstop = 4,
    shiftwidth = 4,                          -- the number of spaces inserted for each indentation
    showmode = true,                         -- we don't need to see things like -- INSERT -- anymore
    showtabline = 2,                         -- always show tabs
    sidescrolloff = 8,
    signcolumn = "yes",                      -- always show the sign column, otherwise it would shift the text each time
    smartcase = true,                        -- smart case
    smartindent = true,                      -- make indenting smarter again
    splitbelow = true,                       -- force all horizontal splits to go below current window
    splitright = true,                       -- force all vertical splits to go to the right of current window
    swapfile = false,                        -- creates a swapfile
    termguicolors = true,                    -- set term gui colors (most terminals support this)
    textwidth = 79,
    timeoutlen = 500,                        -- time to wait for a mapped sequence to complete (in milliseconds)
    timeout = true,
    title = true,
    undofile = true,                         -- enable persistent undo
    updatetime = 250,                        -- faster completion (4000ms default)
    wrap = false,                            -- display lines as one long line
    writebackup = false,                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
}

vim.opt.shortmess:append "c"
vim.opt.listchars = {tab = '▸ ', trail = '·'}

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set formatoptions-=cro]] -- TODO: this doesn't seem to work
