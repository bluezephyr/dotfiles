return {
  -- Adds git releated signs to the gutter, as well as utilities for managing changes
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },

      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true })

        map('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true })
      end
    },
  },

  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
  },

  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' },
  },

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
  },

  -- Clear search highlights after you move your cursor.
  'haya14busa/is.vim',

  -- Tim Pope
  -- https://github.com/tpope/vim-unimpaired, etc
  'tpope/vim-unimpaired',

  -- https://github.com/tpope/vim-surround, etc
  'tpope/vim-surround',

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
  'tpope/vim-repeat',

  -- https://github.com/christoomey/vim-tmux-navigator
  'christoomey/vim-tmux-navigator',

  -- Theme christoomey/vim-tmux-navigator
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000
  },

  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',

    config = function()
      require("bufferline").setup {}
    end,
  },

  -- https://github.com/MeanderingProgrammer/render-markdown.nvim
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {},
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  },

  -- Plugin for the built in commenting https://github.com/folke/ts-comments.nvim
  {
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
}
