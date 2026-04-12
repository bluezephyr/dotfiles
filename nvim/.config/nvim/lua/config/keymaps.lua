-- Note that a lot of keymaps are set in other files. Typically in the
-- configuration files for specific plugins.

local wk = require("which-key")

wk.add({
  { "<leader>f", group = "[F]ind" },
  { "<leader>s", group = "[S]ource" },
  { "<leader>t", group = "[T]oggle" },
  { "<leader>g", group = "[G]it" },
  { "<leader>b", group = "[B]uild" },
  { "<leader>d", group = "[D]ebug" },
})

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Use ESC to exit insert mode in :term
vim.keymap.set("t", "<ESC>", "<C-\\><C-n>", { desc = 'Exit Terminal mode' })

-- Resize with arrows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = 'Increase vertical window size' })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = 'Decrease vertical window size' })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = 'Decrease horizontal window size' })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = 'Increase horizontal window size' })

-- Buffer management
-- See also plugins/snacks.lua
vim.keymap.set("n", "<S-l>", ":bnext<CR>", { desc = 'Next buffer' })
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>w', "<cmd>wall!<CR>", { desc = 'Write all buffers' })
-- vim.keymap.set('n', '<leader>q', require('mini.bufremove').delete, { desc = 'Close buffer' })
vim.keymap.set('n', '<leader>e', "<cmd>qa<CR>", { desc = 'Exit nvim' })
vim.keymap.set('n', '<leader>-', "<cmd>split<CR>", { desc = 'Split window horizontally' })
vim.keymap.set('n', '<leader>\\', "<cmd>vsplit<CR>", { desc = 'Split window vertically' })
vim.keymap.set('n', '<leader>x', "<cmd>close<CR>", { desc = 'Close window' })
vim.keymap.set("n", "<leader>o", "<cmd>only<CR>", { desc = 'Set the current buffer as the only visible' })
vim.keymap.set({ "i", "v", "n", "s" }, "<C-s>", require('save_file').save_file, { desc = 'Write buffer' })

-- Insert --
vim.keymap.set("i", "jj", "<ESC>", { desc = '' })
vim.keymap.set("i", "kk", "<ESC>", { desc = '' })

-- Visual --
-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", { desc = '' })
vim.keymap.set("v", ">", ">gv", { desc = '' })

-- Maintain the cursor position when yanking a visual selection
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set("v", "y", "myy`y", { desc = '' })
vim.keymap.set("v", "Y", "myY`y", { desc = '' })

-- Visual Block --
-- Move text up and down
vim.keymap.set("v", "J", ":move '>+1<CR>gv-gv", { desc = 'Move down' })
vim.keymap.set("v", "K", ":move '<-2<CR>gv-gv", { desc = 'Move up' })

-- Quickfix list
vim.keymap.set("n", "<A-j>", "<cmd>cnext<CR>", { desc = 'Next quickfix' })
vim.keymap.set("n", "<A-k>", "<cmd>cprevious<CR>", { desc = 'Previous quickfix' })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Command to toggle vim options
-- See also https://neovim.io/doc/user/lua.html#lua-vim-options
function Toggle_formatoption(option)
  local action
  if vim.opt.formatoptions:get()[option] then
    vim.opt.formatoptions:remove(option)
    action = " disabled"
  else
    vim.opt.formatoptions:append(option)
    action = " enabled"
  end
  vim.notify("formatoptions " .. option .. action)
end

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Lazy
vim.keymap.set("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- Git
local gs = package.loaded.gitsigns
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", { desc = "Git blame line" })
vim.keymap.set("n", "<leader>gB", function() require('gitsigns').blame_line { full = true } end,
  { desc = "Git blame line full" })
vim.keymap.set("n", "<leader>ge", "<cmd>Gitsigns blame<cr>", { desc = "Git blame" })
vim.keymap.set("n", "<leader>gd", function() require('gitsigns').diffthis() end, { desc = "Git diff this" })
vim.keymap.set("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "Git preview hunk inline" })
vim.keymap.set("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Git preview hunk" })
vim.keymap.set("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Git reset hunk" })
vim.keymap.set("n", "<leader>ga", "<cmd>Gitsigns stage_hunk<cr>", { desc = "Git stage hunk" })
vim.keymap.set("n", "<leader>gu", "<cmd>Gitsigns undo_stage_hunk<cr>", { desc = "Git undo stage hunk" })
vim.keymap.set("n", "<leader>gv", "<cmd>Gitsigns select_hunk<cr>", { desc = "Git select hunk" })
vim.keymap.set("n", "<leader>tg", "<cmd>Gitsigns toggle_current_line_blame<cr>", { desc = "[T]oggle [G]it blame line" })
vim.keymap.set("n", "<leader>ts", "<cmd>Gitsigns toggle_signs<cr>", { desc = "[T]oggle Git [Signs]" })
vim.keymap.set("n", "<leader>tm", "<cmd>Markview toggle<cr>", { desc = "[T]oggle [M]arkview" })
vim.keymap.set('n', ']c', function()
  if vim.wo.diff then return ']c' end
  vim.schedule(function() gs.next_hunk({ target = 'all' }) end)
  return '<Ignore>'
end, { desc = 'Next git hunk', expr = true })

vim.keymap.set('n', '[c', function()
  if vim.wo.diff then return '[c' end
  vim.schedule(function() gs.prev_hunk({ target = 'all' }) end)
  return '<Ignore>'
end, { desc = 'Previous git hunk', expr = true })

-- Convenient shortcuts
vim.keymap.set("n", "<leader>tl", "<cmd>setlocal relativenumber!<CR>", { desc = '[T]oggle relative [L]ine numbers' })
vim.keymap.set("n", "<leader>ta", "<cmd>lua Toggle_formatoption('a')<CR>", { desc = '[T]oggle [A]uto format (a)' })
vim.keymap.set("n", "<leader>tw", "<cmd>set invwrap<CR>", { desc = '[T]oggle [W]rap mode' })
vim.keymap.set("n", "<leader>.", "<cmd>cd %:p:h<CR>:pwd<CR>", { desc = 'Change dir to current file' })
vim.keymap.set("n", "<leader>u", "<cmd>cd ..<CR>:pwd<CR>", { desc = 'Change dir to parent directory' })
vim.keymap.set("n", "<leader>y", "yiw", { desc = 'Yank inside word' })
vim.keymap.set("n", "<leader>p", 'viw"_dP', { desc = 'Paste inside word' })
vim.keymap.set("v", "p", '"_dP', { desc = '' })

-- Re-mappings for commenting (new in 0.10)
vim.keymap.set({ "v", "n" }, "<leader>c", "gcc", { desc = 'Comment line (toggle)', remap = true })

-- Additional folding keymap
vim.keymap.set({ "v", "n" }, "zh", "zc", { desc = 'Close fold under cursor', remap = true })
vim.keymap.set({ "v", "n" }, "<A-h>", "zc", { desc = 'Close fold under cursor', remap = true })
vim.keymap.set({ "v", "n" }, "zl", "zo", { desc = 'Open fold under cursor', remap = true })
vim.keymap.set({ "v", "n" }, "<A-l>", "zo", { desc = 'Open fold under cursor', remap = true })
