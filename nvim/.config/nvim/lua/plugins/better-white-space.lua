return {
  {
    -- https://github.com/ntpeters/vim-better-whitespace
    'ntpeters/vim-better-whitespace',
    priority = 1000,
    init = function()
      vim.cmd "let g:better_whitespace_operator=''"
      vim.keymap.set('n', '<leader>sb',  "<cmd>StripWhitespace<CR>", { desc = 'Strip Whitespaces' })
      vim.keymap.set('n', '<leader>sB',  "<cmd>StripWhitespaceOnChangedLines<CR>", { desc = 'Strip Whitespaces (changes)' })
    end,
  },
}
