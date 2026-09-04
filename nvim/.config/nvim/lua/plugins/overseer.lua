-- See https://github.com/stevearc/overseer.nvim
-- A task runner and job management plugin for Neovim
-- See `:help overseer`

-- Builds live in Overseer's in-memory buffers, which stream while a build runs,
-- and are copied to a per-task log on completion. Reached with <leader>l and
-- <leader>fl, so they stay off the buffer list.
local LOG_ROOT = vim.fn.stdpath("state") .. "/overseer_out"
local KEEP_LOGS = 50
local PICKER_TITLE = "Builds"
-- Tinting only 'Normal' would colour the text area alone: the region past the
-- last line and the number and sign columns are painted by their own groups,
-- which keep their own background. Each of these gets a derived group with the
-- tint background and its original foreground, so line numbers stay dim.
local TINT_GROUPS = { "Normal", "EndOfBuffer", "SignColumn", "LineNr", "CursorLineNr", "FoldColumn" }
local build_win_hl = ""
local MSG_NO_BUILDS = "No builds"

local function define_tint()
  local tint = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).bg
  -- CursorLine matches NormalFloat in some themes and would vanish in the tint.
  local cursor = vim.api.nvim_get_hl(0, { name = "Visual", link = false }).bg
  vim.api.nvim_set_hl(0, "OverseerBuildCursorLine", { bg = cursor })
  -- A theme hides the end-of-buffer markers by drawing them in the background
  -- colour; such a foreground has to move with the tint to stay hidden.
  local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local parts = { "NormalNC:OverseerBuildNormal", "CursorLine:OverseerBuildCursorLine" }
  for _, group in ipairs(TINT_GROUPS) do
    local base = vim.api.nvim_get_hl(0, { name = group, link = false })
    local fg = base.fg == normal_bg and tint or base.fg
    vim.api.nvim_set_hl(0, "OverseerBuild" .. group, { fg = fg, bg = tint })
    parts[#parts + 1] = group .. ":OverseerBuild" .. group
  end
  build_win_hl = table.concat(parts, ",")
end

-- task id -> log path, assigned when the task appears so the filename carries
-- the build's start time.
local log_path_by_task = {}
local run_counter = 0
-- buffer -> lines already written to its log. BufUnload fires before
-- VimLeavePre, so both run for a build still on screen when Neovim exits.
local saved_lines = {}

-- Which project this session's builds belong to. Pinned when Neovim starts so
-- that changing directory does not silently switch to another project's logs;
-- <leader>bs re-anchors it deliberately.
local build_root = nil

local function set_build_root()
  local dir = vim.uv.cwd()
  build_root = vim.fs.root(dir, ".git") or dir
end

-- Logs are grouped per project, so a picker in one project never offers
-- another's builds. The hash keeps repos that share a name apart.
local function get_project_log_dir()
  local name = (vim.fs.basename(build_root) or "build"):gsub("[^%w%-_.]", "_")
  return ("%s/%s-%s"):format(LOG_ROOT, name, vim.fn.sha256(build_root):sub(1, 8))
end

local function get_log_files(dir)
  dir = dir or get_project_log_dir()
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  local files = vim.fn.readdir(dir)
  -- Timestamp leads the filename, so a plain sort is chronological.
  table.sort(files)
  return files
end

local function prune_logs(dir, protect)
  local files = get_log_files(dir)
  for i = 1, #files - KEEP_LOGS do
    local path = dir .. "/" .. files[i]
    if path ~= protect then
      vim.fn.delete(path)
    end
  end
end

-- The last path component named in the command; the project is the folder.
local function build_label(task)
  local cmd = type(task.cmd) == "table" and task.cmd or { tostring(task.cmd or "") }
  local leaf
  for _, arg in ipairs(cmd) do
    local text = tostring(arg)
    if text:find("/") then
      leaf = text:match("([^/]+)/*$")
    end
  end
  -- No path in the command: the last word is usually the target.
  if not leaf or leaf == "" then
    leaf = tostring(cmd[#cmd] or "")
  end
  return (leaf:gsub("[^%w%-_.]", "_"))
end

local function log_path_for(task)
  local path = log_path_by_task[task.id]
  if not path then
    -- The counter separates builds started within the same second.
    run_counter = run_counter + 1
    path = ("%s/%s-%d-%s.log"):format(
      get_project_log_dir(), os.date("%Y%m%d-%H%M%S"), run_counter, build_label(task))
    log_path_by_task[task.id] = path
  end
  return path
end

local function get_task_for_buf(bufnr)
  for _, task in ipairs(require("overseer").list_tasks()) do
    if task:get_bufnr() == bufnr then
      return task
    end
  end
end

-- Appends only what the buffer gained since its last save, so a build saved
-- twice (once mid-build, once after) lands in one log.
local function save_buffer(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  -- Ownership first: this runs for every buffer that unloads, and reading a
  -- large one costs far more than the task-list scan.
  local task = get_task_for_buf(bufnr)
  if not task then
    return
  end
  -- Line count, not 'changedtick': that reads as -1 for every buffer once
  -- Neovim starts exiting, which would let the whole buffer through a second
  -- time. min() covers a buffer that Overseer refilled from the start.
  local total = vim.api.nvim_buf_line_count(bufnr)
  local from = math.min(saved_lines[bufnr] or 0, total)
  local lines = vim.api.nvim_buf_get_lines(bufnr, from, -1, false)
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return
  end
  local path = log_path_for(task)
  local dir = vim.fs.dirname(path)
  vim.fn.mkdir(dir, "p")
  -- A log is a record, so it rests read-only; the mode is relaxed only for the
  -- append, which a build closed mid-flight needs a second time.
  pcall(vim.uv.fs_chmod, path, tonumber("644", 8))
  local handle = io.open(path, "a")
  if not handle then
    pcall(vim.uv.fs_chmod, path, tonumber("444", 8))
    return
  end
  handle:write(table.concat(lines, "\n"), "\n")
  handle:close()
  pcall(vim.uv.fs_chmod, path, tonumber("444", 8))
  saved_lines[bufnr] = total
  prune_logs(dir, path)
end

-- Builds still held in a task buffer. Reads the assigned log path rather than
-- asking for one, so listing never allocates a filename.
local function get_live_items(dir)
  local items = {}
  for _, task in ipairs(require("overseer").list_tasks()) do
    local bufnr = task:get_bufnr()
    -- A task belongs to whichever project its log was assigned to, which is not
    -- the current one if the build directory was re-anchored since.
    local path = bufnr and log_path_by_task[task.id]
    -- is_loaded, not just get_bufnr(): after :bd the handle stays valid but empty.
    if path and vim.api.nvim_buf_is_loaded(bufnr) and vim.fs.dirname(path) == dir then
      items[#items + 1] = {
        key = vim.fs.basename(path),
        label = ("%s  (%s)"):format(build_label(task), task.status:lower()),
        bufnr = bufnr,
      }
    end
  end
  return items
end

-- One item per build: the live buffer where one exists, otherwise the saved log.
-- Keyed by the log filename so the merged list is newest-first across both.
local function get_build_items()
  local dir = get_project_log_dir()
  local items = get_live_items(dir)
  local covered = {}
  for _, item in ipairs(items) do
    covered[item.key] = true
  end
  for _, name in ipairs(get_log_files(dir)) do
    local path = dir .. "/" .. name
    if not covered[name] then
      -- Drop the sort prefix; keep the time, which separates runs of one build.
      local hh, mm, label = name:match("^%d+%-(%d%d)(%d%d)%d%d%-%d+%-(.*)%.log$")
      items[#items + 1] = {
        key = name,
        label = label and ("%s  %s:%s"):format(label, hh, mm) or name,
        path = path,
      }
    end
  end
  table.sort(items, function(a, b)
    return a.key > b.key
  end)
  return items
end

-- Windows that take part in the layout - floats (notifications, pickers) do not.
local function get_layout_wins()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      wins[#wins + 1] = win
    end
  end
  return wins
end

-- Fills the build window until the first build of the session arrives.
local placeholder_buf = nil

local function get_placeholder_buf()
  if not (placeholder_buf and vim.api.nvim_buf_is_valid(placeholder_buf)) then
    placeholder_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[placeholder_buf].bufhidden = "hide"
    -- Named, or :edit would reuse this empty buffer instead of opening its own.
    pcall(vim.api.nvim_buf_set_name, placeholder_buf, "overseer://builds")
    vim.bo[placeholder_buf].modifiable = false
  end
  return placeholder_buf
end

-- A live task's output, a saved log or the placeholder, however it came to be
-- on screen. The placeholder counts so an empty build window keeps its tint
-- and stays closeable with <leader>l.
local function is_build_buf(bufnr)
  return bufnr == placeholder_buf
    or get_task_for_buf(bufnr) ~= nil
    or vim.startswith(vim.api.nvim_buf_get_name(bufnr), LOG_ROOT .. "/")
end

-- Show a build in the current window: its live buffer if it still has one,
-- otherwise the saved log.
local function open_item(item)
  if item.bufnr and vim.api.nvim_buf_is_loaded(item.bufnr) then
    vim.api.nvim_set_current_buf(item.bufnr)
  else
    vim.cmd.edit(vim.fn.fnameescape(item.path))
  end
end

-- A slot rather than a buffer: while it exists it always shows the newest build.
-- Toggling on always creates a split; toggling off destroys it, so no window you
-- arranged is ever taken over.
local build_win = nil
-- What the build window is meant to show, and a guard so the seal below lets
-- our own changes through.
local build_buf = nil
local setting_build_buf = false

local function set_tint(win, on)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  if on then
    vim.wo[win].winhighlight = build_win_hl
  elseif vim.wo[win].winhighlight == build_win_hl then
    -- Leave a winhighlight set for other reasons alone.
    vim.wo[win].winhighlight = ""
  end
end

-- Splitting copies window-local options, so a split of the build window
-- inherits the tint. Strip it from every window that is not the tracked one,
-- leaving any winhighlight set for other reasons alone.
local function sweep_tints()
  if build_win_hl == "" then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= build_win and vim.wo[win].winhighlight == build_win_hl then
      vim.wo[win].winhighlight = ""
    end
  end
end

-- The tracked window still exists and still shows a build.
local function is_build_win_live()
  return build_win ~= nil
    and vim.api.nvim_win_is_valid(build_win)
    and is_build_buf(vim.api.nvim_win_get_buf(build_win))
end

-- Stop tracking a window that was closed or navigated elsewhere, handing it
-- back looking like any other. Leaves build_win nil when tracking has lapsed.
local function release_stale_build_win()
  if build_win and not is_build_win_live() then
    set_tint(build_win, false)
    build_win = nil
    build_buf = nil
  end
end

local function show_in_build_win(item)
  vim.api.nvim_set_current_win(build_win)
  setting_build_buf = true
  local ok = pcall(open_item, item)
  setting_build_buf = false
  if ok then
    build_buf = vim.api.nvim_win_get_buf(build_win)
  end
  set_tint(build_win, true)
end

-- Where a buffer goes when it would otherwise land in the build window: the
-- window focused before it, else the first other one. A window already showing
-- a build is a last resort.
local function get_redirect_win()
  local ordered = { vim.fn.win_getid(vim.fn.winnr("#")) }
  vim.list_extend(ordered, get_layout_wins())
  local fallback
  for _, win in ipairs(ordered) do
    if win ~= build_win and win ~= 0 and vim.api.nvim_win_is_valid(win)
      and vim.api.nvim_win_get_config(win).relative == "" then
      if not is_build_buf(vim.api.nvim_win_get_buf(win)) then
        return win
      end
      fallback = fallback or win
    end
  end
  return fallback
end

-- The build window is a slot, so nothing may quietly take it over. A buffer
-- opened while it has focus is handed to another window instead, leaving the
-- build on screen. With no other window there is nowhere to hand it to.
-- Takes the arriving buffer from the event: the window still reports the old
-- one at BufWinEnter.
local function seal_build_win(incoming)
  if setting_build_buf or not build_win or not vim.api.nvim_win_is_valid(build_win) then
    return
  end
  if vim.api.nvim_get_current_win() ~= build_win then
    return
  end
  if incoming == build_buf or not (build_buf and vim.api.nvim_buf_is_valid(build_buf)) then
    return
  end
  local target = get_redirect_win()
  if not target then
    return
  end
  -- Scheduled: the command that opened the buffer is still running and would
  -- re-assert it in this window.
  local win, keep = build_win, build_buf
  vim.schedule(function()
    if not (vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_is_valid(target)) then
      return
    end
    setting_build_buf = true
    vim.api.nvim_win_set_buf(win, keep)
    vim.api.nvim_win_set_buf(target, incoming)
    setting_build_buf = false
    -- Re-assert tracking: the release pass ran while the window was off-build.
    build_win, build_buf = win, keep
    set_tint(win, true)
    vim.api.nvim_set_current_win(target)
  end)
end

-- Point the build window at the newest build, on every task-list update. Only
-- live builds can be newest here, so the saved logs need not be listed.
local function follow_latest()
  release_stale_build_win()
  if not build_win then
    return
  end
  local newest
  for _, item in ipairs(get_live_items(get_project_log_dir())) do
    if not newest or item.key > newest.key then
      newest = item
    end
  end
  if newest and vim.api.nvim_win_get_buf(build_win) ~= newest.bufnr then
    setting_build_buf = true
    vim.api.nvim_win_set_buf(build_win, newest.bufnr)
    setting_build_buf = false
    build_buf = newest.bufnr
  end
end

-- Toggle the build window. Only the tracked window closes; logs opened with
-- <leader>fl are left alone. The buffer stays loaded so a running build keeps
-- filling it.
local function toggle_build_output()
  release_stale_build_win()
  if build_win then
    local win = build_win
    build_win = nil
    set_tint(win, false)
    if #get_layout_wins() > 1 then
      vim.api.nvim_win_close(win, false)
      return
    end
    -- A tabpage cannot have zero windows, so when the build is the only one it
    -- is replaced in place by the last buffer shown. That buffer must not be a
    -- build itself, or the next toggle stacks a second build view on top of it.
    local alt = vim.fn.bufnr("#")
    local reusable = alt > 0 and vim.api.nvim_buf_is_valid(alt) and not is_build_buf(alt)
    if not (reusable and pcall(vim.cmd, "buffer #")) then
      vim.cmd("enew")
    end
    return
  end

  -- botright, not split: a plain :split divides the *current* window, so the
  -- build would land mid-layout. This spans the full width at the very bottom.
  vim.cmd("botright split")
  build_win = vim.api.nvim_get_current_win()
  local item = get_build_items()[1]
  if item then
    show_in_build_win(item)
  else
    -- follow_latest() swaps the first build in as soon as one runs.
    setting_build_buf = true
    vim.api.nvim_win_set_buf(build_win, get_placeholder_buf())
    setting_build_buf = false
    build_buf = get_placeholder_buf()
    set_tint(build_win, true)
  end
end

local function confirm_log(picker, entry)
  picker:close()
  open_item(entry.item)
end

-- The picker hands back the item itself, so repeated labels need no suffix.
local function pick_log()
  local items = get_build_items()
  if #items == 0 then
    vim.notify(MSG_NO_BUILDS, vim.log.levels.WARN)
    return
  end

  local entries = {}
  for _, item in ipairs(items) do
    entries[#entries + 1] = {
      text = item.label,
      file = item.path,
      buf = item.bufnr,
      item = item,
    }
  end

  Snacks.picker.pick({
    title = PICKER_TITLE,
    items = entries,
    format = "text",
    preview = "file",
    confirm = confirm_log,
  })
end

return {
  'stevearc/overseer.nvim',

  opts = {
    output = {
      -- A terminal buffer pads out to the window height; a nofile buffer is
      -- exactly as long as the output, with ANSI escapes stripped.
      use_terminal = false,
    },

    component_aliases = {
      -- This REPLACES Overseer's own list. `on_complete_dispose` is left out so
      -- old builds stay reachable; dispose by hand with <leader>ba.
      default = {
        "on_exit_set_status",
        "on_complete_notify",
        -- Errors into the quickfix list. `items_only` drops lines 'errorformat'
        -- does not match; the window never opens by itself.
        { "on_output_quickfix", items_only = true, tail = true },
      },
    },
  },

  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    set_build_root()
    define_tint()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("overseer_build_tint", { clear = true }),
      callback = define_tint,
    })

    -- Name and unlist the output buffers, and give each task its log path.
    -- Re-asserted every update because restarting a task resets 'buflisted'.
    vim.api.nvim_create_autocmd("User", {
      pattern = "OverseerListUpdate",
      group = vim.api.nvim_create_augroup("overseer_output_buffers", { clear = true }),
      callback = function()
        for _, task in ipairs(overseer.list_tasks()) do
          local bufnr = task:get_bufnr()
          if bufnr then
            log_path_for(task)
            if vim.api.nvim_buf_get_name(bufnr) == "" then
              pcall(vim.api.nvim_buf_set_name, bufnr, ("overseer://%s #%d"):format(task.name, task.id))
            end
            vim.bo[bufnr].buflisted = false
            -- Save once the build ends; save_buffer() appends only new lines,
            -- so the repeat events cost nothing.
            if task.status ~= "PENDING" and task.status ~= "RUNNING" then
              save_buffer(bufnr)
            end
          end
        end
        follow_latest()
      end,
    })

    -- Saved logs are ordinary file buffers, so unlist those too. BufWinEnter is
    -- needed as well: `:edit` on a loaded buffer re-sets 'buflisted' without
    -- re-reading the file.
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost", "BufWinEnter" }, {
      group = vim.api.nvim_create_augroup("overseer_output_unlist", { clear = true }),
      pattern = LOG_ROOT .. "/*",
      callback = function(args)
        vim.bo[args.buf].buflisted = false
        vim.bo[args.buf].modifiable = false
        vim.bo[args.buf].readonly = true
        -- mini.trailspace skips a buffer only for its 'buftype', and a saved log
        -- is an ordinary file, so its highlight takes the per-buffer opt-out.
        vim.b[args.buf].minitrailspace_disable = true
      end,
    })

    -- Drop the tint the moment the window stops showing a build, rather than
    -- waiting for the next <leader>l.
    vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter", "WinClosed" }, {
      group = vim.api.nvim_create_augroup("overseer_build_win", { clear = true }),
      callback = function(args)
        if args.event == "BufWinEnter" then
          seal_build_win(args.buf)
        end
        release_stale_build_win()
        sweep_tints()
      end,
    })

    local group = vim.api.nvim_create_augroup("overseer_output_save", { clear = true })

    -- Catch anything discarded before it completed. Ownership comes from the
    -- task list, not 'filetype': Overseer does not restore the filetype when it
    -- refills a buffer.
    vim.api.nvim_create_autocmd("BufUnload", {
      group = group,
      callback = function(args)
        save_buffer(args.buf)
      end,
    })

    -- Whatever is still open when Neovim exits.
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        for _, task in ipairs(overseer.list_tasks()) do
          local bufnr = task:get_bufnr()
          if bufnr then
            save_buffer(bufnr)
          end
        end
      end,
    })
  end,

  vim.keymap.set('n', '<leader>br', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<F3>', "<cmd>OverseerRun<CR>", { desc = '[B]uild [R]un' }),
  vim.keymap.set('n', '<leader>l', toggle_build_output, { desc = 'Toggle build output, [l]atest' }),
  vim.keymap.set('n', '<leader>fl', pick_log, { desc = 'Build [L]ogs (saved)' }),
  vim.keymap.set('n', '<leader>bs', function()
    set_build_root()
    vim.notify("Build directory: " .. build_root)
  end, { desc = '[B]uild directory [S]et to cwd' }),
  vim.keymap.set('n', '<F2>', "<cmd>OverseerToggle<CR>", { desc = '[B]uild [T]oggle' }),
  vim.keymap.set('n', '<leader>bo', "<cmd>OverseerOpen<CR>", { desc = '[B]uild [O]pen' }),
  vim.keymap.set('n', '<leader>ba', "<cmd>OverseerTaskAction<CR>", { desc = '[B]uild task [A]ction' }),
  vim.keymap.set('n', '<leader>bc', "<cmd>OverseerClose<CR>", { desc = '[B]uild [C]lose' }),
}
