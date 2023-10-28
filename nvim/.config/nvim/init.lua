-- Remap space as leader key
-- keymap("", "<Space>", "<Nop>", { desc = '' })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require "config.lazy"
require "config.options"
require "config.keymaps"
