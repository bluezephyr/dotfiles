local grep_opts = {
  "--hidden",
  "--iglob",
  '"!**/.git/*"',
  "--column",
  "--line-number",
  "--no-heading",
  "--color=always",
  "--smart-case",
  "--max-columns=4096",
  "-e",
}

return {
  -- https://github.com/ibhagwan/fzf-lua
  "ibhagwan/fzf-lua",
  lazy = false,
  -- https://github.com/echasnovski/mini.icons
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    winopts = {
      fullscreen = true
      -- preview = { layout = "horizontal" }
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
          winopts = { preview = { layout = "horizontal", } },
          rg_opts = table.concat(grep_opts, " "),
          hidden = true,
        })
      end,
      desc = "Live grep (fzf)"
    },
    {
      "<leader>fu",
      function()
        require("fzf-lua").live_grep({
          grep = {
            glob_flag      = "--iglob", -- for case sensitive globs use '--glob'
            glob_separator = "%s%-%-" -- query separator pattern (lua): ' --'
          },
          winopts = {
            preview = {
              layout = "horizontal",
            }
          },
        })
      end,
      desc = "Live grep glob (fzf)"
    },
    {
      "<leader>fz",
      function()
        require("fzf-lua").builtin()
      end,
      desc = "Buitin (fzf)"
    },
    {
      "<leader><leader>",
      function()
        require("fzf-lua").buffers({ previewer = false, winopts = { fullscreen = false } })
      end,
      desc = "Buffers",
    }
  }
}
