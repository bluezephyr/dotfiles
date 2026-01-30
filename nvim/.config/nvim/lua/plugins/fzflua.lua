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
    "borderless-full",
    winopts = {
      fullscreen = true,
    },
   -- files = {
    --   -- toggle_ignore = true,
    --   -- toggle_ignore_flag = "--no-ignore-vcs",
    --   -- file_icons = false,
    -- },
    -- keymap = {
    --   builtin = {
    --     ["<C-d>"] = "preview-page-down",
    --     ["<C-u>"] = "preview-page-up",
    --   },
    -- },
  },
  keys = {
    {
      "<leader>fk",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>h",
      function()
        require("fzf-lua").help_tags()
      end,
      desc = "Help tags",
    },
    {
      "<leader>fc",
      function()
        require("fzf-lua").commands()
      end,
      desc = "Commands",
    },
    {
      "<leader>fd",
      function()
        require("fzf-lua").workspace_diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>fo",
      function()
        require("fzf-lua").nvim_options()
      end,
      desc = "Vim Options",
    },
    {
      "<leader>fm",
      function()
        require("fzf-lua").manpages()
      end,
      desc = "Manpages",
    },
    {
      "<leader>fr",
      function()
        require("fzf-lua").resume()
      end,
      desc = "Resume",
    },
    {
      "<leader>fh",
      function()
        require("fzf-lua").oldfiles()
      end,
      desc = "History",
    },
    {
      "<leader>fi",
      function()
        require("fzf-lua").files({
          cwd = vim.fn.expand("~/index"),
          fd_opts = "--type file --hidden --follow --strip-cwd-prefix",
        })
      end,
      desc = "Index",
    },
    {
      "<leader>ff",
      function()
        require("fzf-lua").files({
          toggle_ignore = true,
          toggle_ignore_flag = "--no-ignore-vcs",
          -- Add the default actions explicitly to get a help text
          actions = {
            ["alt-i"] = require("fzf-lua.actions").toggle_ignore,
            ["alt-h"] = require("fzf-lua.actions").toggle_hidden,
          },
        })
      end,
      desc = "Files",
    },
    {
      "<leader>f.",
      function()
        require("fzf-lua").files({
          cwd = vim.fn.expand("%:p:h"),
          -- Add the default actions explicitly to get a help text
          actions = {
            ["alt-i"] = require("fzf-lua.actions").toggle_ignore,
            ["alt-h"] = require("fzf-lua.actions").toggle_hidden,
          },
        })
      end,
      desc = "Files in current folder",
    },
    {
      "<leader>fn",
      function()
        require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Neovim config",
    },
    {
      "<leader>fg",
      function()
        require("fzf-lua").live_grep({
          winopts = { preview = { layout = "vertical" } },
          rg_opts = rg_opts,
          hidden = true,
        })
      end,
      desc = "Live Grep (fzf)",
    },
    {
      "<leader>fw",
      function()
        require("fzf-lua").grep_cword({
          winopts = { preview = { layout = "vertical" } },
        })
      end,
      desc = "Grep Word (fzf)",
    },
    {
      "<leader>fz",
      function()
        require("fzf-lua").builtin()
      end,
      desc = "Buitin (fzf)",
    },
    {
      "<leader>fb",
      function()
        require("fzf-lua").marks({
          winopts = { preview = { layout = "vertical" } },
        })
      end,
      desc = "Marks",
    },
    {
      "<leader>'",
      function()
        require("fzf-lua").marks({
          winopts = { preview = { layout = "vertical" } },
        })
      end,
      desc = "Marks",
    },
    {
      "<leader><leader>",
      function()
        require("fzf-lua").buffers({ previewer = false, winopts = { fullscreen = false } })
      end,
      desc = "Buffers",
    },
    {
      "<leader>gs",
      function()
        require("fzf-lua").git_status(fzf_git_winopts)
      end,
      desc = "Git status",
    },
    {
      "<leader>gl",
      function()
        require("fzf-lua").git_commits(fzf_git_winopts)
      end,
      desc = "Git log",
    },
    {
      "<leader>m",
      function()
        require("fzf-lua").fzf_exec(vim.split(vim.fn.execute("messages"), "\n"), {
          prompt = "Messages> ",
          fzf_opts = { ["--no-sort"] = true },
          actions = {
            ["default"] = function(selected)
              vim.notify(table.concat(selected, "\n"))
            end,
          },
        })
      end,
      desc = "Messages",
    },

    -- LSP keymaps. See lsp.lua for other configuration
    -- for details of the lsp filtering
    {
      "<leader>ss",
      function()
        require("fzf-lua").lsp_document_symbols({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: Document Symbols",
    },
    {
      "<leader>sw",
      function()
        require("fzf-lua").lsp_workspace_symbols({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: Workspace Symbols",
    },
    {
      "<leader>si",
      function()
        require("fzf-lua").lsp_incoming_calls({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: Incoming Calls",
    },
    {
      "<leader>sf",
      function()
        require("fzf-lua").lsp_finder({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: Find all locations",
    },
    {
      "gr",
      function()
        require("fzf-lua").lsp_references({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: References",
    },
    {
      "<leader>sD",
      function()
        require("fzf-lua").lsp_document_diagnostics({
          winopts = {
            fullscreen = true,
            preview = { layout = "vertical" },
          },
        })
      end,
      desc = "LSP: Show All Diagnostics",
    },
  },
}
