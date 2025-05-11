return {
  "ibhagwan/fzf-lua",
  -- https://github.com/echasnovski/mini.icons
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    winopts = {
      preview = { layout = "vertical" }
    },
  },
  keys = {
    {
      "<leader>mf",
      function()
        require("fzf-lua").files()
      end,
      desc = "Find Files (fzf)"
    },
    {
      "<leader>mn",
      function()
        require("fzf-lua").files({ cwd = vim.fn.stdpath('config') })
      end,
      desc = "Find Neovim Config (fzf)"
    }
  }
}
