-- Options for rg to ignore .git
local rg_opts =
"--hidden --iglob '!**/.git/*' --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e"

local fzf_git_winopts = {
  winopts = {
    preview = {
      layout = "vertical",
      vertical = "down:70%",
    },
  },
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
    files = {
      -- toggle_ignore = true,
      -- toggle_ignore_flag = "--no-ignore-vcs",
      file_icons = false,
    },
    -- keymap = {
    --   builtin = {
    --     ["<C-d>"] = "preview-page-down",
    --     ["<C-u>"] = "preview-page-up",
    --   },
    -- },
  },
  keys = {
    { "<leader>fk", function() require("fzf-lua").keymaps() end,               desc = "[F]ind [K]eymaps" },
    { "<leader>fh", function() require("fzf-lua").help_tags() end,             desc = "[F]ind [H]elp" },
    { "<leader>fc", function() require("fzf-lua").commands() end,              desc = "[F]ind [C]ommands" },
    { "<leader>fd", function() require("fzf-lua").workspace_diagnostics() end, desc = "[F]ind [D]iagnostics" },
    { "<leader>fo", function() require("fzf-lua").nvim_options() end,          desc = "[F]ind Vim [O]ptions" },
    { "<leader>fm", function() require("fzf-lua").manpages() end,              desc = "[F]ind [M]anpages" },
    {
      "<leader>ff",
      function()
        require("fzf-lua").files({
          toggle_ignore = true,
          toggle_ignore_flag = "--no-ignore-vcs",
          -- Add the default actions explicitly to get a help text
          actions = {
            ["alt-i"] = require("fzf-lua.actions").toggle_ignore,
            ["alt-h"] = require("fzf-lua.actions").toggle_hidden
          },
        })
      end,
      desc = "[F]ind [F]iles"
    },
    {
      "<leader>f.",
      function()
        require("fzf-lua").files({
          cwd = vim.fn.expand('%:p:h'),
          -- Add the default actions explicitly to get a help text
          actions = {
            ["alt-i"] = require("fzf-lua.actions").toggle_ignore,
            ["alt-h"] = require("fzf-lua.actions").toggle_hidden
          },
        })
      end,
      desc = "[F]ind Files Relative Current"
    },
    {
      "<leader>fn",
      function()
        require("fzf-lua").files({ cwd = vim.fn.stdpath('config') })
      end,
      desc = "[F]ind [N]eovim Config"
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").live_grep({
          winopts = { preview = { layout = "vertical", } },
          rg_opts = rg_opts,
          hidden = true,
        })
      end,
      desc = "Live [G]rep (fzf)"
    },
    {
      "<leader>fw",
      function()
        require("fzf-lua").grep_cword({
          winopts = { preview = { layout = "vertical", } },
        })
      end,
      desc = "Grep [W]ord (fzf)"
    },
    {
      "<leader>fz",
      function()
        require("fzf-lua").builtin()
      end,
      desc = "Buitin (fzf)"
    },
    {
      "<leader>fb",
      function()
        require("fzf-lua").marks({
          winopts = { preview = { layout = "vertical", } },
        })
      end,
      desc = "[F]ind marks"
    },
    {
      "<leader>'",
      function()
        require("fzf-lua").marks({
          winopts = { preview = { layout = "vertical", } },
        })
      end,
      desc = "[F]ind marks"
    },
    {
      "<leader><leader>",
      function()
        require("fzf-lua").buffers({ previewer = false, winopts = { fullscreen = false } })
      end,
      desc = "Buffers",
    },
    { "<leader>gs", function() require("fzf-lua").git_status(fzf_git_winopts) end,  desc = "[G]it [S]tatus" },
    { "<leader>gl", function() require("fzf-lua").git_commits(fzf_git_winopts) end, desc = "[G]it [L]og" },

    -- LSP keymaps. See lsp.lua for other configuration
    -- for details of the lsp filtering
    {
      "<leader>ss",
      function()
        require("fzf-lua").lsp_document_symbols({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: Document Symbols"
    },
    {
      "<leader>sw",
      function()
        require("fzf-lua").lsp_workspace_symbols({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: Workspace Symbols"
    },
    {
      "<leader>si",
      function()
        require("fzf-lua").lsp_incoming_calls({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: Incoming Calls"
    },
    {
      "<leader>sf",
      function()
        require("fzf-lua").lsp_finder({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: Find all locations"
    },
    {
      "gr",
      function()
        require("fzf-lua").lsp_references({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: References"
    },
    {
      "<leader>sD",
      function()
        require("fzf-lua").lsp_document_diagnostics({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" }
          }
        })
      end,
      desc = "LSP: Show All Diagnostics"
    },
  }
}
