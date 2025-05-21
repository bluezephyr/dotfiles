local grep_opts = {
  "rg",
  "--vimgrep",
  "--hidden",
  -- "--follow",
  "--glob",
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
  "ibhagwan/fzf-lua",
  -- https://github.com/echasnovski/mini.icons
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    winopts = {
      fullscreen = true,
      preview = { layout = "horizontal" }
    },
    grep = {
      cwd_prompt = false,
      -- prompt = Utils.icons.misc.search .. " ",
      input_prompt = "Grep For ❯ ",
      cmd = table.concat(grep_opts, " "),
      hidden = true,
      -- follow = true,
    }
  },
  keys = {
    {
      "<leader>ff",
      function()
        require("fzf-lua").files()
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
      "<leader>fi",
      function()
        require("fzf-lua").files({ cwd = vim.fn.expand('~/index/') })
      end,
      desc = "Find Index (fzf)"
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").live_grep()
      end,
      desc = "Live grep (fzf)"
    },
    {
      "<leader>fw",
      function()
        require("fzf-lua").grep_cword()
      end,
      desc = "Grep word (fzf)"
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
        require("fzf-lua").buffers({ previewer = false, winopts = { fullscreen = false }})
      end,
      desc = "Buffers",
    }
  }
}
