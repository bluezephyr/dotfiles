-- See https://github.com/stevearc/overseer.nvim
-- A task runner and job management plugin for Neovim
-- See `:help overseer`

-- Builds live in Overseer's in-memory buffers, which stream while a build runs,
-- and are copied to a per-task log on completion. Reached with <leader>l and
-- <leader>fl, so they stay off the buffer list.
local LOG_ROOT = vim.fn.stdpath("state") .. "/overseer_out"
local KEEP_LOGS = 50
local PICKER_PROMPT = "Builds> "
-- Tinting only 'Normal' would colour the text area alone: the region past the
-- last line and the number and sign columns are painted by their own groups,
-- which keep their own background. Each of these gets a derived group with the
-- tint background and its original foreground, so line numbers stay dim.
local TINT_GROUPS = { "Normal", "EndOfBuffer", "SignColumn", "LineNr", "CursorLineNr", "FoldColumn" }
local build_win_hl = ""

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
-- Both entry points list the current project only, so neither can claim there
-- are no builds at all.
local MSG_NO_BUILDS = "No builds"

-- task id -> log path, assigned when the task appears so the filename carries
-- the build's start time.
local log_path_by_task = {}
local run_counter = 0
-- buffer -> 'changedtick' at its last save. BufUnload fires before VimLeavePre,
-- so without this both would append the same content.
local saved_tick = {}

-- Which project this session's builds belong to. Pinned when Neovim starts so
-- that changing directory does not silently switch to another project's logs;
-- <leader>bs re-anchors it deliberately.
local build_root = nil

local function set_build_root(dir)
  dir = dir or vim.uv.cwd()
  build_root = vim.fs.root(dir, ".git") or dir
  return build_root
end

-- Logs are grouped per project, so a picker in one project never offers
-- another's builds. The hash keeps repos that share a name apart.
local function project_dir()
  local root = build_root or set_build_root()
  local name = (vim.fs.basename(root) or "build"):gsub("[^%w%-_.]", "_")
  return ("%s/%s-%s"):format(LOG_ROOT, name, vim.fn.sha256(root):sub(1, 8))
end

local function log_files(dir)
  dir = dir or project_dir()
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  local files = vim.fn.readdir(dir)
  -- Timestamp leads the filename, so a plain sort is chronological.
  table.sort(files)
  return files
end

local function prune_logs(dir, protect)
  local files = log_files(dir)
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
      project_dir(), os.date("%Y%m%d-%H%M%S"), run_counter, build_label(task))
    log_path_by_task[task.id] = path
  end
  return path
end

local function task_for_buf(bufnr)
  for _, task in ipairs(require("overseer").list_tasks()) do
    if task:get_bufnr() == bufnr then
      return task
    end
  end
end

-- Appends, so a buffer saved twice (once mid-build, once after) lands in one log.
local function save_buffer(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local tick = vim.b[bufnr].changedtick
  if saved_tick[bufnr] == tick then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 or (#lines == 1 and lines[1] == "") then
    return
  end
  local task = task_for_buf(bufnr)
  if not task then
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
    return
  end
  handle:write(table.concat(lines, "\n"), "\n")
  handle:close()
  pcall(vim.uv.fs_chmod, path, tonumber("444", 8))
  saved_tick[bufnr] = tick
  prune_logs(dir, path)
end

-- One item per build: the live buffer where one exists, otherwise the saved log.
-- Keyed by the log filename so the merged list is newest-first across both.
local function build_items()
  local dir = project_dir()
  local items, covered = {}, {}
  for _, task in ipairs(require("overseer").list_tasks()) do
    -- is_loaded, not just get_bufnr(): after :bd the handle stays valid but empty.
    local bufnr = task:get_bufnr()
    -- A task belongs to whichever project its log was assigned to, which is not
    -- the current one if the build directory was re-anchored since.
    local path = bufnr and log_path_for(task)
    if bufnr and vim.api.nvim_buf_is_loaded(bufnr) and vim.fs.dirname(path) == dir then
      covered[path] = true
      items[#items + 1] = {
        key = vim.fs.basename(path),
        label = ("%s  (%s)"):format(build_label(task), task.status:lower()),
        bufnr = bufnr,
      }
    end
  end
  for _, name in ipairs(log_files(dir)) do
    local path = dir .. "/" .. name
    if not covered[path] then
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
local function layout_wins()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      wins[#wins + 1] = win
    end
  end
  return wins
end

-- A live task's output or a saved log, however it came to be on screen.
local function is_build_buf(bufnr)
  return task_for_buf(bufnr) ~= nil
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

local function set_tint(win, on)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.wo[win].winhighlight = on and build_win_hl or ""
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

-- Tracking lapses once the window is gone or shows something else.
local function build_win_valid()
  if build_win and vim.api.nvim_win_is_valid(build_win) and is_build_buf(vim.api.nvim_win_get_buf(build_win)) then
    return true
  end
  -- Navigated elsewhere: hand the window back looking like any other.
  set_tint(build_win, false)
  build_win = nil
  return false
end

local function show_in_build_win(item)
  vim.api.nvim_set_current_win(build_win)
  open_item(item)
  set_tint(build_win, true)
end

-- Point the build window at the newest build, on every task-list update.
local function follow_latest()
  if not build_win_valid() then
    return
  end
  local item = build_items()[1]
  if item and item.bufnr and vim.api.nvim_win_get_buf(build_win) ~= item.bufnr then
    vim.api.nvim_win_set_buf(build_win, item.bufnr)
  end
end

-- Toggle the build window. Only the tracked window closes; logs opened with
-- <leader>fl are left alone. The buffer stays loaded so a running build keeps
-- filling it.
local function toggle_build_output()
  if build_win_valid() then
    local win = build_win
    build_win = nil
    set_tint(win, false)
    if #layout_wins() > 1 then
      vim.api.nvim_win_close(win, false)
    -- A tabpage cannot have zero windows, so when the build is the only one it
    -- is replaced in place by the last buffer shown, or an empty one.
    elseif not pcall(vim.cmd, "buffer #") then
      vim.cmd("enew")
    end
    return
  end

  local item = build_items()[1]
  if not item then
    vim.notify(MSG_NO_BUILDS, vim.log.levels.WARN)
    return
  end
  -- botright, not split: a plain :split divides the *current* window, so the
  -- build would land mid-layout. This spans the full width at the very bottom.
  vim.cmd("botright split")
  build_win = vim.api.nvim_get_current_win()
  show_in_build_win(item)
end

-- fzf hands back the entry string, so the picker maps labels to items itself
-- rather than relying on fzf-lua parsing a path out of the entry text.
local function pick_log()
  local items = build_items()
  if #items == 0 then
    vim.notify(MSG_NO_BUILDS, vim.log.levels.WARN)
    return
  end

  local lookup, entries = {}, {}
  for _, item in ipairs(items) do
    local entry = item.label
    -- Labels repeat when one build runs twice in a minute; keep them unique.
    local n = 1
    while lookup[entry] do
      n = n + 1
      entry = ("%s (%d)"):format(item.label, n)
    end
    lookup[entry] = item
    entries[#entries + 1] = entry
  end

  local builtin = require("fzf-lua.previewer.builtin")
  local Previewer = builtin.buffer_or_file:extend()
  function Previewer:new(o, opts)
    Previewer.super.new(self, o, opts)
    setmetatable(self, Previewer)
    return self
  end
  function Previewer:entry_to_file(entry_str)
    local item = lookup[entry_str]
    if item then
      return { path = item.path, bufnr = item.bufnr, line = 0, col = 0 }
    end
    return Previewer.super.entry_to_file(self, entry_str)
  end

  require("fzf-lua").fzf_exec(entries, {
    prompt = PICKER_PROMPT,
    previewer = Previewer,
    actions = {
      ["default"] = function(selected)
        local item = lookup[selected[1]]
        if item then
          open_item(item)
        end
      end,
    },
    -- fzf-lua's "vertical" stacks the preview underneath.
    winopts = { preview = { layout = "vertical", vertical = "down:70%" } },
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
            -- Save once the build ends; nothing is written after that, and
            -- save_buffer()'s changedtick check absorbs the repeat events.
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
      end,
    })

    -- Drop the tint the moment the window stops showing a build, rather than
    -- waiting for the next <leader>l. build_win_valid() does the clearing.
    vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter", "WinClosed" }, {
      group = vim.api.nvim_create_augroup("overseer_build_win", { clear = true }),
      callback = function()
        if build_win then
          build_win_valid()
        end
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
    vim.notify("Build directory: " .. set_build_root())
  end, { desc = '[B]uild directory [S]et to cwd' }),
  vim.keymap.set('n', '<F2>', "<cmd>OverseerToggle<CR>", { desc = '[B]uild [T]oggle' }),
  vim.keymap.set('n', '<leader>bo', "<cmd>OverseerOpen<CR>", { desc = '[B]uild [O]pen' }),
  vim.keymap.set('n', '<leader>ba', "<cmd>OverseerTaskAction<CR>", { desc = '[B]uild task [A]ction' }),
  vim.keymap.set('n', '<leader>bc', "<cmd>OverseerClose<CR>", { desc = '[B]uild [C]lose' }),
}
