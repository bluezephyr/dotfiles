-- Adds git releated signs to the gutter, as well as utilities for managing changes
return {
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

      -- 'all' reaches staged hunks too; the default stops at unstaged ones.
      map(']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gs.nav_hunk('next', { target = 'all' })
        end
      end, 'Next git hunk')
      map('[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gs.nav_hunk('prev', { target = 'all' })
        end
      end, 'Previous git hunk')

      map('<leader>gb', function() gs.blame_line({ full = true }) end, 'Git blame line full')
      map('<leader>ge', gs.blame, 'Git blame')
      map('<leader>gd', gs.diffthis, 'Git diff this')
      map('<leader>gp', gs.preview_hunk_inline, 'Git preview hunk inline')
      map('<leader>gh', gs.preview_hunk, 'Git preview hunk')
      map('<leader>gr', gs.reset_hunk, 'Git reset hunk')
      -- On a staged hunk this unstages it again.
      map('<leader>ga', gs.stage_hunk, 'Git stage hunk (toggle)')
      map('<leader>gv', gs.select_hunk, 'Git select hunk')

      map('<leader>tg', gs.toggle_current_line_blame, '[T]oggle [G]it blame line')
      map('<leader>ts', gs.toggle_signs, '[T]oggle Git [Signs]')
    end,
  },
}
