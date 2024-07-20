return {
  {
    -- https://github.com/ntpeters/vim-better-whitespace
    'ntpeters/vim-better-whitespace',
    priority = 1000,
    init = function()
      vim.cmd "let g:better_whitespace_operator=''"
    end,
  },
}
