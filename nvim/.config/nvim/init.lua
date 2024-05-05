-- Remap space as leader key
-- keymap("", "<Space>", "<Nop>", { desc = '' })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Install package manager
-- https://github.com/folke/lazy.nvim
-- `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- All plugins are added to separate files in ~/.config/nvim/lua/plugins
require('lazy').setup('plugins')

require "options"
require "keymaps"
