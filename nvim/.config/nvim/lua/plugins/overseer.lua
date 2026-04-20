-- See https://github.com/stevearc/overseer.nvim
-- A task runner and job management plugin for Neovim
-- See `:help .txt`

return {
  'stevearc/overseer.nvim',

  opts = {},

  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    -- Inject a component into every task that streams output to the build log
    overseer.add_template_hook(nil, function(task_defn, util)
      util.add_component(task_defn, "build_log_append")
    end)
  end,

  vim.keymap.set('n', '<leader>br', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<F3>', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<leader>l', function() require("build_log").toggle() end, { desc = 'Build [l]og' }),
  vim.keymap.set('n', '<F2>', "<cmd>OverseerToggle<CR>", { desc = '[B]uild [T]oggle' }),
  vim.keymap.set('n', '<leader>bo', "<cmd>OverseerOpen<CR>", { desc = '[B]uild [O]pen' }),
  vim.keymap.set('n', '<leader>bc', "<cmd>OverseerClose<CR>", { desc = '[B]uild [C]lose' }),
  vim.keymap.set('n', '<leader>be', function() require("build_log").clear() end, { desc = '[B]uild [E]rase log' }),
}
