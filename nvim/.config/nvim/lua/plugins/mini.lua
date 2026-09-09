local style = require('style')

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

-- Marks the directory holding the file.
local DIR_ICON = ''

-- How far the directory is dimmed toward the background it sits on.
local DIM_AMOUNT = 0.45

-- Severities shown in the statusline, each in its own colour.
local DIAGNOSTIC_LEVELS = {
  { name = 'ERROR', sign = 'E', hl = 'MiniStatuslineDiagError', source = 'DiagnosticError' },
  { name = 'WARN', sign = 'W', hl = 'MiniStatuslineDiagWarn', source = 'DiagnosticWarn' },
  { name = 'INFO', sign = 'I', hl = 'MiniStatuslineDiagInfo', source = 'DiagnosticInfo' },
  { name = 'HINT', sign = 'H', hl = 'MiniStatuslineDiagHint', source = 'DiagnosticHint' },
}

-- Paints the accents onto the backgrounds mini gives their sections, so a
-- colorscheme switch keeps the emphasis.
local function style_statusline()
  local fg, bg = style.hl('Normal').fg, style.hl('MiniStatuslineFilename').bg
  vim.api.nvim_set_hl(0, 'MiniStatuslineName', { fg = fg, bg = bg, bold = true })
  -- Blended rather than borrowed from Comment, whose colour some themes set
  -- to exactly this background.
  local dim = fg and bg and style.blend(fg, bg, DIM_AMOUNT) or style.hl('Comment').fg
  vim.api.nvim_set_hl(0, 'MiniStatuslineDir', { fg = dim, bg = bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModified', { fg = style.hl('DiagnosticWarn').fg, bg = bg, bold = true })

  local devinfo = style.hl('MiniStatuslineDevinfo').bg
  for _, level in ipairs(DIAGNOSTIC_LEVELS) do
    vim.api.nvim_set_hl(0, level.hl, { fg = style.hl(level.source).fg, bg = devinfo })
  end
end

-- The buffer's name, then the full directory holding it, shortened to ~ where
-- it sits under the home directory.
local function filename_section()
  if vim.bo.buftype == 'terminal' then
    return '%#MiniStatuslineName#%t'
  end

  local path = vim.api.nvim_buf_get_name(0)
  local name, dir = '%f', ''
  if path ~= '' then
    name = vim.fn.fnamemodify(path, ':t')
    dir = DIR_ICON .. ' ' .. vim.fn.fnamemodify(path, ':~:h') .. '/'
  end

  return table.concat({
    '%#MiniStatuslineName#', name,
    '%#MiniStatuslineModified#%m%r',
    '%#MiniStatuslineDir#    ', dir,
  })
end

-- mini takes the filetype icon from mini.icons, whose glyphs differ from the
-- devicons set the bufferline showed. Swap it, keeping the rest of mini's.
local function fileinfo_section()
  local info = require('mini.statusline').section_fileinfo({})
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if not ok or info:sub(1, #vim.bo.filetype) == vim.bo.filetype then
    return info
  end
  return (info:gsub('^%S+', devicons.get_icon(vim.fn.expand('%:t'), nil, { default = true }), 1))
end

-- Diagnostic counts in mini's own format, one highlight group per severity.
local function diagnostics_section()
  if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
    return ''
  end

  local counts, parts = vim.diagnostic.count(0), {}
  for _, level in ipairs(DIAGNOSTIC_LEVELS) do
    local n = counts[vim.diagnostic.severity[level.name]] or 0
    if n > 0 then
      table.insert(parts, ('%%#%s# %s%d'):format(level.hl, level.sign, n))
    end
  end
  if #parts == 0 then
    return ''
  end

  return '' .. table.concat(parts, '') .. '%#MiniStatuslineDevinfo#'
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
        content = {
          active = function()
            local mode     = statusline.section_mode({})
            local git      = statusline.section_git({})
            local location = statusline.section_location({})

            return statusline.combine_groups({
              { hl = 'MiniStatuslineMode',     strings = { mode } },
              { hl = 'MiniStatuslineFilename', strings = { filename_section() } },
              -- Align the rest of the items to the right
              '%=',
              { hl = 'MiniStatuslineDevinfo',  strings = { git, diagnostics_section() } },
              { hl = 'MiniStatuslineFileinfo', strings = { fileinfo_section() } },
              { hl = 'MiniStatuslineLocation', strings = { location } },
            })
          end,
        },
      })

      -- The statusline sits at the top, where the bufferline used to.
      vim.o.tabline = '%!v:lua.MiniStatusline.active()'

      style_statusline()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = style_statusline })

      -- mini redraws the statusline on these; a tabline needs its own nudge.
      vim.api.nvim_create_autocmd({ 'DiagnosticChanged', 'LspAttach', 'LspDetach' }, {
        group = vim.api.nvim_create_augroup('statusline_tabline', { clear = true }),
        callback = function() vim.cmd('redrawtabline') end,
      })
    end
  },
}
