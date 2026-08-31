-- Adds git releated signs to the gutter, as well as utilities for managing changes

-- Browsing an older base: the signs are recoloured and the window grows a
-- winbar, since hunks then describe a past change rather than working changes.
local ACCENT = 'DiagnosticHint'
local SIGN_GROUPS = {
  'GitSignsAdd', 'GitSignsChange', 'GitSignsDelete',
  'GitSignsTopdelete', 'GitSignsChangedelete', 'GitSignsUntracked',
}
local MAX_COMMITS = 50
local base_hl = ''

-- buffer -> { commits = {...}, index = n }. Index 0 is the default base.
local state = {}

local function define_base_hl()
  local accent = vim.api.nvim_get_hl(0, { name = ACCENT, link = false }).fg
  local parts = {}
  for _, group in ipairs(SIGN_GROUPS) do
    vim.api.nvim_set_hl(0, group .. 'Base', { fg = accent })
    parts[#parts + 1] = group .. ':' .. group .. 'Base'
  end
  base_hl = table.concat(parts, ',')
end

-- gitsigns reads the file at the base revision, so a revision that predates
-- the file cannot serve as one.
local function base_has_file(dir, base, name)
  return vim.system({ 'git', '-C', dir, 'cat-file', '-e', base .. ':./' .. name }):wait().code == 0
end

-- Commits that touched this file, newest first. --follow keeps a rename's
-- history attached.
local function file_commits(path)
  local dir = vim.fs.dirname(path)
  local out = vim.system({
    'git', '-C', dir, 'log', '--follow', '-n', tostring(MAX_COMMITS),
    '--format=%h\31%p\31%cr\31%s', '--', path,
  }, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  local commits = {}
  for line in (out.stdout or ''):gmatch('[^\n]+') do
    local sha, parents, when, subject = line:match('^(.-)\31(.-)\31(.-)\31(.*)$')
    if sha then
      -- First parent only: a merge's other side is not this file's history.
      local parent = vim.split(parents, ' ')[1]
      commits[#commits + 1] = {
        sha = sha,
        base = parent ~= '' and parent or nil,
        when = when,
        subject = subject,
      }
    end
  end
  return commits
end

local function current_commit(bufnr)
  local st = state[bufnr]
  if st and st.index > 0 then
    return st.commits[st.index]
  end
end

local function decorate_win(win)
  local commit = current_commit(vim.api.nvim_win_get_buf(win))
  if commit then
    vim.wo[win].winhighlight = base_hl
    vim.wo[win].winbar = ('%%#%sBase# from %s  %s'):format(SIGN_GROUPS[1], commit.sha, commit.subject)
    vim.w[win].gitsigns_base_winbar = true
  else
    if vim.wo[win].winhighlight == base_hl then
      vim.wo[win].winhighlight = ''
    end
    -- Only clear a winbar this module set; winbar is global-local, so a split
    -- does not inherit one and each window is decorated on its own.
    if vim.w[win].gitsigns_base_winbar then
      vim.wo[win].winbar = ''
      vim.w[win].gitsigns_base_winbar = nil
    end
  end
end

local function sweep_bases()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      decorate_win(win)
    end
  end
end

-- Index 0 restores the default base. Returns false when the commit introduced
-- the file, since there is then nothing to diff it against.
local function apply_base(bufnr, index)
  local st = state[bufnr]
  local commit = st.commits[index]
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  if commit and not (commit.base and base_has_file(st.dir, commit.base, name)) then
    vim.notify(('%s starts at %s'):format(name, commit.sha), vim.log.levels.WARN)
    return false
  end
  st.index = index
  require('gitsigns').change_base(commit and commit.base or nil, false, vim.schedule_wrap(sweep_bases))
  return true
end

-- Loads this file's log on first use; returns false when there is none.
local function ensure_commits(bufnr)
  if state[bufnr] then
    return true
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  local commits = path ~= '' and file_commits(path)
  if not commits or #commits == 0 then
    vim.notify('No commits for this file', vim.log.levels.WARN)
    return false
  end
  state[bufnr] = { commits = commits, index = 0, dir = vim.fs.dirname(path) }
  return true
end

local function pick_base()
  local bufnr = vim.api.nvim_get_current_buf()
  if not ensure_commits(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  local entries, by_sha = {}, {}
  for i, c in ipairs(state[bufnr].commits) do
    entries[#entries + 1] = ('%s  %-14s %s'):format(c.sha, c.when, c.subject)
    by_sha[c.sha] = i
  end
  require('fzf-lua').fzf_exec(entries, {
    prompt = 'Base> ',
    preview = ('git -C %s show --color=always {1} -- %s'):format(
      vim.fn.shellescape(vim.fs.dirname(path)), vim.fn.shellescape(path)),
    actions = {
      ['default'] = function(selected)
        local index = selected[1] and by_sha[selected[1]:match('^(%S+)')]
        if index then
          apply_base(bufnr, index)
        end
      end,
    },
  })
end

-- Positive steps move the base further back through this file's history.
local function step_base(delta)
  local bufnr = vim.api.nvim_get_current_buf()
  if not ensure_commits(bufnr) then
    return
  end
  local st = state[bufnr]
  local index = math.max(0, math.min(#st.commits, st.index + delta))
  if index == st.index then
    vim.notify(index == 0 and 'Already at the default base' or 'Oldest commit', vim.log.levels.WARN)
    return
  end
  if not apply_base(bufnr, index) then
    return
  end
  local commit = st.commits[index]
  vim.notify(commit and ('Base: from ' .. commit.sha) or 'Base: default')
end

local function reset_base()
  local bufnr = vim.api.nvim_get_current_buf()
  if current_commit(bufnr) then
    apply_base(bufnr, 0)
  end
end

-- gitsigns marks each popup window with the id of the popup it holds.
local function popup_win(id)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].gitsigns_preview == id then
      return win
    end
  end
end

-- Popups open unfocused, and only once their content has been fetched, so
-- entering one means waiting for the window to appear.
local function enter_popup(open, id, decorate)
  local origin = vim.api.nvim_get_current_win()
  open()
  local win
  vim.wait(1000, function()
    win = popup_win(id)
    return win ~= nil
  end, 20)
  if not win then
    return
  end
  vim.api.nvim_set_current_win(win)
  -- Alongside the q that gitsigns binds. Buffer-local, so it wins over any
  -- global <Esc> mapping while the popup has focus.
  vim.keymap.set('n', '<Esc>', '<cmd>quit!<cr>',
    { buffer = vim.api.nvim_win_get_buf(win), silent = true, desc = 'Close popup' })
  if decorate then
    decorate(win, origin)
  end
end

local function open_hunk_popup()
  require('gitsigns').preview_hunk()
end

local function open_blame_popup()
  require('gitsigns').blame_line({ full = true })
end

local map_popup_steps

-- ]c and [c inside the hunk popup walk the file window's hunks, the popup
-- following along. It is closed first: preview_hunk() focuses an open popup
-- rather than refreshing it.
local function popup_step(origin, direction)
  return function()
    pcall(vim.api.nvim_win_close, 0, true)
    if not vim.api.nvim_win_is_valid(origin) then
      return
    end
    vim.api.nvim_set_current_win(origin)
    require('gitsigns').nav_hunk(direction, { target = 'all' }, vim.schedule_wrap(function()
      enter_popup(open_hunk_popup, 'hunk', map_popup_steps)
    end))
  end
end

map_popup_steps = function(win, origin)
  local buf = vim.api.nvim_win_get_buf(win)
  vim.keymap.set('n', ']c', popup_step(origin, 'next'), { buffer = buf, desc = 'Next git hunk' })
  vim.keymap.set('n', '[c', popup_step(origin, 'prev'), { buffer = buf, desc = 'Previous git hunk' })
end

local function preview_hunk_focused()
  enter_popup(open_hunk_popup, 'hunk', map_popup_steps)
end

-- No stepping here: the popup's "Hunk N of M" counts the blamed commit's own
-- hunks, which the file's hunks have nothing to do with.
local function blame_line_focused()
  enter_popup(open_blame_popup, 'blame')
end

-- Staging and resetting act against the base, so away from the default they
-- would touch a past commit rather than the working change.
local function guarded(action, question)
  return function()
    local commit = current_commit(vim.api.nvim_get_current_buf())
    if commit then
      local prompt = ('Base is before %s, not HEAD.\n%s?'):format(commit.sha, question)
      if vim.fn.confirm(prompt, '&Yes\n&No', 2) ~= 1 then
        return
      end
    end
    action()
  end
end

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

      map('<leader>gb', blame_line_focused, 'Git blame line full')
      map('<leader>ge', gs.blame, 'Git blame')
      map('<leader>gd', gs.diffthis, 'Git diff this')
      map('<leader>gp', gs.preview_hunk_inline, 'Git preview hunk inline')
      map('<leader>gh', preview_hunk_focused, 'Git preview hunk')
      map('<leader>gr', guarded(gs.reset_hunk, 'Reset hunk'), 'Git reset hunk')
      -- On a staged hunk this unstages it again.
      map('<leader>ga', guarded(gs.stage_hunk, 'Stage hunk'), 'Git stage hunk (toggle)')
      map('<leader>gv', gs.select_hunk, 'Git select hunk')

      map('<leader>gc', pick_base, 'Git [c]hange diff base')
      map('<leader>g[', function() step_base(1) end, 'Git base one commit older')
      map('<leader>g]', function() step_base(-1) end, 'Git base one commit newer')
      map('<leader>gC', reset_base, 'Git base back to default')

      -- Both return the new state, which goes to the shared toggle report.
      map('<leader>tg', function()
        Toggle_report('git blame line', gs.toggle_current_line_blame())
      end, '[T]oggle [G]it blame line')
      map('<leader>tG', function()
        Toggle_report('git signs', gs.toggle_signs())
      end, '[T]oggle [G]it signs')
    end,
  },

  config = function(_, opts)
    require('gitsigns').setup(opts)
    define_base_hl()

    local group = vim.api.nvim_create_augroup('gitsigns_diff_base', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = define_base_hl })
    vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter', 'WinNew' }, {
      group = group,
      callback = sweep_bases,
    })
    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
      group = group,
      callback = function(args)
        state[args.buf] = nil
      end,
    })
  end,
}
