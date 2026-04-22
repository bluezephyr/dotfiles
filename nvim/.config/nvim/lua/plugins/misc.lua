return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    config = true,
  },

  -- Clear search highlights after you move your cursor.
  -- https://github.com/haya14busa/is.vim
  'haya14busa/is.vim',

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
        local gs = require('gitsigns')
        local function map(l, r, desc)
          vim.keymap.set('n', l, r, { buffer = bufnr, desc = desc })
        end
        map(']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gs.nav_hunk('next')
          end
        end, 'Next git hunk')
        map('[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gs.nav_hunk('prev')
          end
        end, 'Previous git hunk')
      end,
    },
  },

  -- https://github.com/christoomey/vim-tmux-navigator
  'christoomey/vim-tmux-navigator',

  -- TODD: Remove these?
  -- Detect tabstop and shiftwidth automatically
  -- https://github.com/tpope/vim-sleuth
  -- 'tpope/vim-sleuth',
  -- https://github.com/tpope/vim-repeat
  -- 'tpope/vim-repeat',

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
  },
}
