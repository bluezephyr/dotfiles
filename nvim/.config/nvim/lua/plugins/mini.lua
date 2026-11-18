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

-- How far the bar is tinted from the editor background toward the theme's
-- blue, and the file name lifted from the text colour toward white (black
-- on light themes). In onedark these give #334659 and #eaecef.
local BAR_TINT = 0.2
local INACTIVE_TINT = 0.08
local NAME_LIFT = 0.75

-- Gives every section one background, tinted from the theme, so the bar
-- reads as a whole and keeps its look across colorscheme switches.
local function style_statusline()
  local normal = style.hl('Normal')
  local base = normal.bg or style.hl('StatusLine').bg or 0
  local fg = normal.fg or style.hl('StatusLine').fg or 0xffffff
  local blue = style.hl('Function').fg or fg
  local bg = style.blend(base, blue, BAR_TINT)
  local light = vim.o.background == 'light'

  for _, group in ipairs({ 'MiniStatuslineFilename', 'MiniStatuslineDevinfo', 'MiniStatuslineFileinfo' }) do
    vim.api.nvim_set_hl(0, group, { fg = style.hl(group).fg or fg, bg = bg })
  end
  local name = style.blend(fg, light and 0x000000 or 0xffffff, NAME_LIFT)
  vim.api.nvim_set_hl(0, 'MiniStatuslineName', { fg = name, bg = bg, bold = true })
  -- Blended rather than borrowed from Comment, whose colour some themes set
  -- to exactly this background.
  vim.api.nvim_set_hl(0, 'MiniStatuslineDir', { fg = style.blend(fg, bg, DIM_AMOUNT), bg = bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineModified', { fg = style.hl('DiagnosticWarn').fg, bg = bg, bold = true })

  for _, level in ipairs(DIAGNOSTIC_LEVELS) do
    vim.api.nvim_set_hl(0, level.hl, { fg = style.hl(level.source).fg, bg = bg })
  end
  vim.api.nvim_set_hl(0, 'MiniStatuslineLsp', { fg = blue, bg = bg })
  vim.api.nvim_set_hl(0, 'MiniStatuslineGit', { fg = style.hl('String').fg, bg = bg })

  -- Unfocused windows: a fainter tint, the text dimmed into it.
  local inactive = style.blend(base, blue, INACTIVE_TINT)
  vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = style.blend(fg, inactive, DIM_AMOUNT), bg = inactive })

  -- Caps in the mode colour, rounding it off into the bar.
  for _, mode in ipairs(MODE_GROUPS) do
    local group = 'MiniStatuslineMode' .. mode
    vim.api.nvim_set_hl(0, group .. 'Inner', { fg = style.hl(group).bg, bg = bg })
  end
end

-- The buffer's name, then the full directory holding it, shortened to ~ where
-- it sits under the home directory, and to one letter per level when short.
-- Should the line still not fit, Vim cuts the directory from the left (%<).
-- Windows without focus show it all in one dimmed group.
local function filename_section(short, inactive)
  local hl = function(group) return '%#' .. (inactive and 'MiniStatuslineInactive' or group) .. '#' end
  if vim.bo.buftype == 'terminal' then
    return hl('MiniStatuslineName') .. '%t'
  end

  local path = vim.api.nvim_buf_get_name(0)
  local name, dir = '%f', ''
  if path ~= '' then
    name = vim.fn.fnamemodify(path, ':t')
    dir = vim.fn.fnamemodify(path, ':~:h')
    dir = DIR_ICON .. ' ' .. (short and vim.fn.pathshorten(dir) or dir) .. '/'
  end

  return table.concat({
    hl('MiniStatuslineName'), name,
    hl('MiniStatuslineModified'), '%m%r',
    hl('MiniStatuslineDir'), '    %<', dir,
  })
end

-- The first line from build(level) that fits the window, raising the level
-- (dropping or shortening more) until it does.
local function fit(build, max_level)
  local win_width = vim.api.nvim_win_get_width(0)
  for level = 0, max_level do
    local line = build(level)
    local width = vim.api.nvim_eval_statusline((line:gsub('%%=', '')), { maxwidth = 10000 }).width
    if width <= win_width or level == max_level then
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
            -- mini's location, padded so the bar does not shift while moving:
            -- the line to the width of the line count, the column and line
            -- length to three.
            local location = ('%%%dl|%%L│%%3v|%%-3{virtcol("$") - 1}')
              :format(#tostring(vim.api.nvim_buf_line_count(0)))
            local diagnostics, lsp = diagnostics_section(), lsp_section()
            -- e.g. `markdown 󱐋 marksman`
            local fileinfo = table.concat(vim.tbl_filter(function(x) return x ~= '' end, { fileinfo_section(), lsp }), ' ')

            -- When short of space: drop the git branch, then the filetype and
            -- LSP, then shorten the directory. Mode and file name always stay.
            return fit(function(level)
              local info = level < 2 and fileinfo or ''
              return statusline.combine_groups({
                -- Both ends in the mode's colour, as mini's own layout has them.
                { hl = mode_hl,                  strings = { mode } },
                '%#' .. mode_hl .. 'Inner#' .. CAP_RIGHT,
                { hl = 'MiniStatuslineFilename', strings = { filename_section(level >= 3) } },
                -- Align the rest of the items to the right
                '%=',
                { hl = 'MiniStatuslineGit',      strings = { level < 1 and git or '' } },
                { hl = 'MiniStatuslineDevinfo',  strings = { diagnostics } },
                { hl = 'MiniStatuslineFileinfo', strings = { info } },
                '%#' .. mode_hl .. 'Inner#' .. CAP_LEFT,
                { hl = mode_hl,                  strings = { location } },
              })
            end, 3)
          end,
          inactive = function()
            return '%#MiniStatuslineInactive# ' .. filename_section(false, true) .. '%='
          end,
        },
      })

      -- Each window carries its own statusline at the top, evaluated in that
      -- window; the full one only where the cursor is. The real statusline
      -- stays blank, to separate horizontal splits.
      vim.go.winbar = '%{%nvim_get_current_win() ==# g:actual_curwin'
        .. ' ? v:lua.MiniStatusline.active() : v:lua.MiniStatusline.inactive()%}'
      vim.go.statusline = ' '

      style_statusline()
      vim.api.nvim_create_autocmd('ColorScheme', { callback = style_statusline })
    end
  },
}
