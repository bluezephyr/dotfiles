-- See https://github.com/stevearc/overseer.nvim
-- A task runner and job management plugin for Neovim
-- See `:help .txt`
return {
  'stevearc/overseer.nvim',

  -- Disable DAP initially, enable when loading nvim-dap
  -- https://github.com/stevearc/overseer.nvim/blob/master/doc/third_party.md#dap
  -- opts = { dap = false },
  opts = {},

  vim.keymap.set('n', '<leader>br', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<F3>', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<leader>bt', "<cmd>OverseerToggle<CR>", { desc = '[B]uild [T]oggle' }),
  vim.keymap.set('n', '<F2>', "<cmd>OverseerToggle<CR>", { desc = '[B]uild [T]oggle' }),
  vim.keymap.set('n', '<leader>bo', "<cmd>OverseerOpen<CR>", { desc = '[B]uild [O]pen' }),
  vim.keymap.set('n', '<leader>bc', "<cmd>OverseerClose<CR>", { desc = '[B]uild [C]lose' }),
}
