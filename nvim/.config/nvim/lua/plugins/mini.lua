return {
  -- https://github.com/echasnovski/mini.nvim/tree/main
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.ai').setup()
      -- require('mini.bufremove').setup()
      require('mini.surround').setup()
      require('mini.bracketed').setup()
      require('mini.basics').setup()
      require('mini.operators').setup()
      require('mini.icons').setup()

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
