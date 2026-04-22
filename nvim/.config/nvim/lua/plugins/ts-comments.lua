-- Plugin for the built in commenting https://github.com/folke/ts-comments.nvim
return {
  "folke/ts-comments.nvim",
  opts = {
    lang = {
      c = "// %s",
      cpp = "// %s",
    },
  },
  event = "VeryLazy",
  enabled = vim.fn.has("nvim-0.10.0") == 1,

  -- The lang parameter does not seem to work for cpp files. Local fix below
  config = function()
    vim.cmd [[ au FileType cpp setlocal commentstring=//\ %s ]]
    vim.cmd [[ au FileType c setlocal commentstring=//\ %s ]]
  end,
}
