-- Toggle mini.trailspace's highlight of trailing whitespace.
local function toggle_trailspace()
  local trailspace = require('mini.trailspace')
  vim.g.minitrailspace_disable = not vim.g.minitrailspace_disable
  if vim.g.minitrailspace_disable then
    trailspace.unhighlight()
  else
    trailspace.highlight()
  end
end

return {
  -- https://github.com/echasnovski/mini.nvim/tree/main
  {
    'echasnovski/mini.nvim',
    version = false,
    event = "VeryLazy",
    config = function()
      require('mini.ai').setup()
      -- require('mini.bufremove').setup()
      require('mini.surround').setup()
      require('mini.bracketed').setup()
      -- Disable the default `\` option-toggle prefix: it made `\` both a complete
      -- mapping (Neotree) and a prefix of 11 others, forcing a 'timeoutlen' wait.
      -- The toggles worth keeping live under <leader>t in config/keymaps.lua.
      require('mini.basics').setup({ mappings = { option_toggle_prefix = '' } })
      require('mini.operators').setup()
      require('mini.icons').setup()
      require('mini.trailspace').setup()
      vim.keymap.set('n', '<leader>sb', require('mini.trailspace').trim, { desc = 'Strip Whitespaces' })
      vim.keymap.set('n', '<leader>th', toggle_trailspace, { desc = '[T]oggle Whitespace [H]ighlight' })

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
