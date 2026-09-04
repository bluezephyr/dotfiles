-- Toggle mini.trailspace's highlight of trailing whitespace, in every buffer.
local function toggle_trailspace()
  local trailspace = require('mini.trailspace')
  vim.g.minitrailspace_disable = not vim.g.minitrailspace_disable
  if vim.g.minitrailspace_disable then
    trailspace.unhighlight()
  else
    trailspace.highlight()
  end
  Toggle_report('trailspace', not vim.g.minitrailspace_disable)
end

return {
  -- https://github.com/echasnovski/mini.nvim/tree/main
  {
    'echasnovski/mini.nvim',
    version = false,
    event = "VeryLazy",
    config = function()
      require('mini.ai').setup()
      require('mini.surround').setup()
      require('mini.bracketed').setup()

      -- Disable the default `\` option-toggle prefix: it made `\` both a complete
      -- mapping (Neotree) and a prefix of 11 others, forcing a 'timeoutlen' wait.
      -- The toggles worth keeping live under <leader>t in config/keymaps.lua.
      require('mini.basics').setup({ mappings = { option_toggle_prefix = '' } })
      -- No `replace`: its `gr` prefix shadows the LSP references picker, and
      -- takes Neovim's own gr* LSP mappings with it.
      require('mini.operators').setup({ replace = { prefix = '' } })
      require('mini.icons').setup()

      -- Skip buffers with a non-empty 'buftype', where trailing space does not
      -- matter: Overseer's live build output among them.
      require('mini.trailspace').setup({ only_in_normal_buffers = true })
      vim.keymap.set('n', '<leader>sb', require('mini.trailspace').trim, { desc = 'Strip Whitespaces' })
      vim.keymap.set('n', '<leader>tt', toggle_trailspace, { desc = '[T]oggle [T]railspace' })
      -- Bug: mini.trailspace restores the highlight on InsertLeave but not on
      -- TermLeave, so a file opened from a terminal buffer stays unhighlighted.
      -- Workaround: restore it on TermLeave.
      vim.api.nvim_create_autocmd('TermLeave', {
        group = vim.api.nvim_create_augroup('trailspace_termleave', { clear = true }),
        callback = function() require('mini.trailspace').highlight() end,
      })

      local statusline = require('mini.statusline')
      statusline.setup({
        use_icons = true,

        content = {
          active = function(args)
            args              = args or {}
            local mode        = statusline.section_mode(args)
            local git         = statusline.section_git(args)
            local diagnostics = statusline.section_diagnostics(args)
            local filename    = statusline.section_filename(args)
            local fileinfo    = statusline.section_fileinfo(args)
            local location    = statusline.section_location(args)

            -- Show working directory before filename
            local cwd         = ' ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~')

            return statusline.combine_groups({
              { hl = 'MiniStatuslineMode',     strings = { mode } },
              { hl = 'MiniStatuslineDevinfo',  strings = { git, diagnostics } },
              { hl = 'MiniStatuslineFilename', strings = { cwd, ' | ', filename } },
              -- Align the rest of the items to the right
              '%=',
              { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
              { hl = 'MiniStatuslineLocation', strings = { location } },
            })
          end,
        },
      })
    end
  },
}
