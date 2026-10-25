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

-- Half circles that round off the mode-coloured sections where they meet
-- another section; at the screen edges they stay square.
local CAP_LEFT, CAP_RIGHT = '', ''

-- The groups mini colours the mode with; each gets matching caps.
local MODE_GROUPS = { 'Normal', 'Insert', 'Visual', 'Replace', 'Command', 'Other' }

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
  vim.api.nvim_set_hl(0, 'MiniStatuslineName', { fg = style.hl('Identifier').fg or fg, bg = bg, bold = true })
  -- Blended rather than borrowed from Comment, whose colour some themes set
  -- to exactly this background.
  local dim = fg and bg and style.blend(fg, bg, DIM_AMOUNT) or style.hl('Comment').fg
  vim.api.nvim_set_hl(0, 'MiniStatuslineDir', { fg = dim, bg = bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModified', { fg = style.hl('DiagnosticWarn').fg, bg = bg, bold = true })

  local devinfo = style.hl('MiniStatuslineDevinfo').bg
  for _, level in ipairs(DIAGNOSTIC_LEVELS) do
    vim.api.nvim_set_hl(0, level.hl, { fg = style.hl(level.source).fg, bg = devinfo })
  end
  vim.api.nvim_set_hl(0, 'MiniStatuslineLsp', { fg = style.hl('Function').fg, bg = bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGit', { fg = style.hl('String').fg, bg = devinfo })

  -- Themes tend to give the file info the dev info's background; the file
  -- name's instead makes the sections alternate, so each stands apart.
  vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = style.hl('MiniStatuslineFileinfo').fg, bg = bg })

  -- A cap is drawn in the mode colour on the section it borders: the file
  -- name/info, or the dev info when the file info has been dropped for space.
  for _, name in ipairs(MODE_GROUPS) do
    local group = 'MiniStatuslineMode' .. name
    local mode_bg = style.hl(group).bg
    vim.api.nvim_set_hl(0, group .. 'Inner', { fg = mode_bg, bg = bg })
    vim.api.nvim_set_hl(0, group .. 'Dev', { fg = mode_bg, bg = devinfo })
  end
end

-- The buffer's name, then the full directory holding it, shortened to ~ where
-- it sits under the home directory, and to one letter per level when short.
-- Should the line still not fit, Vim cuts the directory from the left (%<).
local function filename_section(short)
  if vim.bo.buftype == 'terminal' then
    return '%#MiniStatuslineName#%t'
  end

  local path = vim.api.nvim_buf_get_name(0)
  local name, dir = '%f', ''
  if path ~= '' then
    name = vim.fn.fnamemodify(path, ':t')
    dir = vim.fn.fnamemodify(path, ':~:h')
    dir = DIR_ICON .. ' ' .. (short and vim.fn.pathshorten(dir) or dir) .. '/'
  end

  return table.concat({
    '%#MiniStatuslineName#', name,
    '%#MiniStatuslineModified#%m%r',
    '%#MiniStatuslineDir#    %<', dir,
  })
end

-- The first line from build(level) that fits the screen, raising the level
-- (dropping or shortening more) until it does.
local function fit(build, max_level)
  for level = 0, max_level do
    local line = build(level)
    local width = vim.api.nvim_eval_statusline((line:gsub('%%=', '')), { maxwidth = 10000 }).width
    if width <= vim.o.columns or level == max_level then
      return line
    end
  end
end

-- mini takes the filetype icon from mini.icons, whose glyphs differ from the
-- devicons set the bufferline showed. Swap it, keeping the rest of mini's.
-- Only the icon and filetype: mini leaves out encoding and size when it
-- counts as truncated, which an endless width makes it always.
local function fileinfo_section()
  local info = require('mini.statusline').section_fileinfo({ trunc_width = math.huge })
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

-- Names of the LSP clients attached to the buffer behind an icon, to follow
-- the filetype, or nothing when there are none.
local function lsp_section()
  local names = vim.tbl_map(function(client) return client.name end, vim.lsp.get_clients({ bufnr = 0 }))
  if #names == 0 then
    return ''
  end
  table.sort(names)
  return '%#MiniStatuslineLsp#󱐋 ' .. table.concat(names, ',') .. '%#MiniStatuslineFileinfo#'
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
      -- mapping (the file explorer) and a prefix of 11 others, forcing a 'timeoutlen' wait.
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
            local mode, mode_hl = statusline.section_mode({})
            local git      = statusline.section_git({})
            local location = statusline.section_location({})
            if git ~= '' then
              git = '%#MiniStatuslineGit#' .. git .. '%#MiniStatuslineDevinfo#'
            end
            local diagnostics, lsp = diagnostics_section(), lsp_section()
            -- e.g. `markdown 󱐋 marksman`
            local fileinfo = table.concat(vim.tbl_filter(function(x) return x ~= '' end, { fileinfo_section(), lsp }), ' ')

            -- When short of space: drop the git branch, then the filetype and
            -- LSP, then shorten the directory. Mode and file name always stay.
            return fit(function(level)
              local info = level < 2 and fileinfo or ''
              local dev_shown = (level < 1 and git ~= '') or diagnostics ~= ''
              local location_border = (info == '' and dev_shown) and 'Dev' or 'Inner'
              return statusline.combine_groups({
                -- Both ends in the mode's colour, as mini's own layout has them.
                { hl = mode_hl,                  strings = { mode } },
                '%#' .. mode_hl .. 'Inner#' .. CAP_RIGHT,
                { hl = 'MiniStatuslineFilename', strings = { filename_section(level >= 3) } },
                -- Align the rest of the items to the right
                '%=',
                { hl = 'MiniStatuslineDevinfo',  strings = { level < 1 and git or '', diagnostics } },
                { hl = 'MiniStatuslineFileinfo', strings = { info } },
                '%#' .. mode_hl .. location_border .. '#' .. CAP_LEFT,
                { hl = mode_hl,                  strings = { location } },
              })
            end, 3)
          end,
        },
      })

      -- The statusline sits at the top, where the bufferline used to.
      vim.o.tabline = '%!v:lua.MiniStatusline.active()'

      style_statusline()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = style_statusline })

      -- A statusline is redrawn on these, a tabline is not: without the nudge
      -- the mode, location and diagnostics would go stale.
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'ModeChanged', 'DiagnosticChanged', 'LspAttach', 'LspDetach' }, {
        group = vim.api.nvim_create_augroup('statusline_tabline', { clear = true }),
        -- On LspDetach the client is still listed, so redraw once it is gone.
        callback = function() vim.schedule(function() vim.cmd('redrawtabline') end) end,
      })
    end
  },
}
