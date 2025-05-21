return {
  -- https://github.com/ibhagwan/fzf-lua
  "ibhagwan/fzf-lua",
  -- https://github.com/echasnovski/mini.icons
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    winopts = {
      fullscreen = true
      -- preview = {
      -- layout = "horizontal",
      -- }
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
      "<leader>ff",
      function()
        require("fzf-lua").files({
          toggle_ignore = true,
          toggle_ignore_flag = "--no-ignore-vcs",
          -- Add '--no-ignore-vcs' to have ignored files shown by default
          fd_opts = "--color=never --hidden --type f --type l --exclude .git",
          -- Add the default actions explicitly to get a help text
          actions = {
            ["alt-i"] = require("fzf-lua.actions").toggle_ignore,
            ["alt-h"] = require("fzf-lua.actions").toggle_hidden
          },
        })
      end,
      desc = "Find Files (fzf)"
    },
    {
      "<leader>fn",
      function()
        require("fzf-lua").files({ cwd = vim.fn.stdpath('config') })
      end,
      desc = "Find Neovim Config (fzf)"
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").live_grep({
          winopts = {
            fullscreen = false,
            preview = {
              layout = "vertical",
            }
          },
        })
      end,
      desc = "Live grep (fzf)"
    }
  }
}
