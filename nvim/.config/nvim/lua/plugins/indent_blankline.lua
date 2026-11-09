-- Add indentation guides even on blank lines
-- https://github.com/lukas-reineke/indent-blankline.nvim/
-- See `:help indent_blankline.txt`
return {
  {
    'lukas-reineke/indent-blankline.nvim',
    main = "ibl",
    opts = {
      -- The current scope's guide is enough: no underline on the lines that
      -- open and close it (a for loop's `for ... do` and `end`).
      scope = { show_start = false, show_end = false },
    },
  },
}
