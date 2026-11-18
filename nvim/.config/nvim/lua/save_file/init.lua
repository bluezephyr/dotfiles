-- Save As: a name field above an explorer, both in one dialog. The name is
-- typed in the field, the folder picked in the tree; Enter in the field
-- saves, after a confirmation popup.
local M = {}

local Snacks = require("snacks")

local function noop() end

-- The dialog's keys, shown by <A-?>: a heading, then key and description.
local HELP = {
  { "Name field" },
  { "<CR>", "save" },
  { "<Esc>", "clear search, else cancel" },
  { "<Tab>", "go to the tree" },
  { "<C-h> <C-l>", "cursor left / right" },
  { "<Up> <Down>", "move in the tree" },
  { "<Left> <Right>", "close / open folder" },
  { "<C-u> <C-d>", "half page up / down" },
  { "<PageUp> <PageDown>", "page up / down" },
  { "/", "search the tree" },
  { "<C-n> <C-p>", "next / previous hit" },
  { "<C-y>", "take the selected file's name" },
  { "<A-n>", "new folder" },
  { "<A-h> <A-i>", "show hidden / ignored files" },
  { "<A-?>", "this help" },
  {},
  { "Tree" },
  { "<CR>", "open / close folder, take file name" },
  { "<Tab>", "back to the name" },
  { "<Esc>", "clear search, else cancel" },
  { "n N", "next / previous hit" },
  { "?", "all explorer keys" },
}

-- Splits text into lines of at most max columns, breaking after a slash or
-- at a space where it can, so paths wrap at their folders.
local function wrap(text, max)
  local lines, line = {}, ""
  for piece in text:gmatch("[^/ ]*[/ ]?") do
    if piece == "" then
      break
    end
    if line ~= "" and #line + #vim.trim(piece) > max then
      lines[#lines + 1] = vim.trim(line)
      line = ""
    end
    line = line .. piece
    while #line > max do
      lines[#lines + 1] = line:sub(1, max)
      line = line:sub(max + 1)
    end
  end
  if vim.trim(line) ~= "" then
    lines[#lines + 1] = vim.trim(line)
  end
  return lines
end

-- line padded on the left to sit in the middle of a width.
local function center(line, width)
  return string.rep(" ", math.max(0, math.floor((width - vim.fn.strdisplaywidth(line)) / 2))) .. line
end

-- Hides the cursor in normal mode, where the tree and the confirm popup
-- have nothing to edit; the search prompt and the text fields keep theirs.
-- Highlighting it with full blend hides it in terminals too, as mini.pick
-- does.
local saved_guicursor
local function hide_cursor()
  if saved_guicursor then
    return
  end
  saved_guicursor = vim.o.guicursor
  vim.api.nvim_set_hl(0, "SaveFileHiddenCursor", { blend = 100, nocombine = true })
  vim.o.guicursor = (saved_guicursor ~= "" and saved_guicursor .. "," or "") .. "n-v-sm:SaveFileHiddenCursor"
end

local function show_cursor()
  if not saved_guicursor then
    return
  end
  -- An empty 'guicursor' would leave it hidden, as mini.pick notes.
  if saved_guicursor == "" then
    vim.cmd("set guicursor=a:")
  end
  vim.o.guicursor = saved_guicursor
  saved_guicursor = nil
end

-- A small popup centred in area ({ row, col, width, height }, the editor
-- by default), entered, with keys of its own. lines are shown as given, so
-- wrapping and centring are the caller's.
local function popup(lines, title, width, area)
  area = area or { row = 0, col = 0, width = vim.o.columns, height = vim.o.lines }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = area.row + math.max(0, math.floor((area.height - #lines - 2) / 2)),
    col = area.col + math.max(0, math.floor((area.width - width - 2) / 2)),
    width = width,
    height = #lines,
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    style = "minimal",
    zindex = 80,
  })
  return buf, win
end

-- How wide a popup is: its text and title, within max.
local function popup_width(text, title, max)
  local wanted = math.max(40, vim.fn.strdisplaywidth(text) + 4, vim.fn.strdisplaywidth(title) + 4)
  return math.min(max or (vim.o.columns - 4), wanted)
end

-- The answers ask() can offer, each picked by its first letter.
local CHOICES = {
  yes = { key = "Y", rest = "es" },
  no = { key = "N", rest = "o" },
  cancel = { key = "C", rest = "ancel" },
}

-- Asks a question with the popup. The question is centred and the choices
-- (opts.choices, default yes and no) spread across the width in that order;
-- the chosen one is bracketed and starts on opts.default. Tab, the arrows
-- and h/l move, Enter takes the chosen one, a first letter answers
-- directly, and Esc, q or leaving the popup mean cancel (no without it).
-- on_answer gets the choice's name.
local function ask(question, opts, on_answer)
  local choices = opts.choices or { "yes", "no" }
  local escape = vim.tbl_contains(choices, "cancel") and "cancel" or "no"
  vim.cmd.stopinsert()
  local w = popup_width(question, "Confirm", opts.area and opts.area.width - 4)
  local lines = {}
  for _, line in ipairs(wrap(question, w - 4)) do
    lines[#lines + 1] = center(line, w)
  end
  vim.list_extend(lines, { "", "" })
  local buf, win = popup(lines, "Confirm", w, opts.area)
  local row = #lines - 1
  local ns = vim.api.nvim_create_namespace("save_file_ask")
  local chosen = math.max(1, vim.fn.index(choices, opts.default or choices[1]) + 1)

  -- Redraws the choices, each in its share of the width.
  local function draw()
    local line, spans = "", {}
    for i, name in ipairs(choices) do
      local choice = CHOICES[name]
      local label = (i == chosen and "[%s]%s" or "(%s)%s"):format(choice.key, choice.rest)
      local share = math.floor(w * i / #choices) - math.floor(w * (i - 1) / #choices)
      local text = center(label, share)
      spans[#spans + 1] = { #line + #text - #label, #line + #text, i == chosen }
      line = line .. text .. string.rep(" ", share - #text)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, row, row + 1, false, { line })
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, span in ipairs(spans) do
      vim.api.nvim_buf_set_extmark(buf, ns, row, span[1], {
        end_col = span[2],
        hl_group = span[3] and "Question" or "Comment",
      })
    end
  end
  draw()

  -- Nothing to edit, so the cursor is hidden while the popup is open.
  hide_cursor()

  local answered = false
  local function answer(name)
    if answered then
      return
    end
    answered = true
    show_cursor()
    pcall(vim.api.nvim_win_close, win, true)
    vim.schedule(function() on_answer(name) end)
  end
  local function set(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  local function move(step)
    return function()
      chosen = (chosen - 1 + step) % #choices + 1
      draw()
    end
  end
  for _, name in ipairs(choices) do
    local key = CHOICES[name].key
    set(key, function() answer(name) end)
    set(key:lower(), function() answer(name) end)
  end
  set("<CR>", function() answer(choices[chosen]) end)
  set("<Esc>", function() answer(escape) end)
  set("q", function() answer(escape) end)
  for _, lhs in ipairs({ "<Tab>", "<Right>", "l" }) do
    set(lhs, move(1))
  end
  for _, lhs in ipairs({ "<S-Tab>", "<Left>", "h" }) do
    set(lhs, move(-1))
  end
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = function() answer(escape) end,
  })
end

-- Folders whose top makes a good root for the tree.
local ROOT_MARKERS = { ".git", ".zk" }

-- Size of the dialog, the field's three rows (with border) included.
local MAX_WIDTH, HEIGHT_RATIO = 80, 0.6

local function buffer_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and vim.fs.normalize(vim.fn.fnamemodify(name, ":p")) or nil
end

-- The tree's top: the project holding the file, else the home folder, else
-- (for a file outside it) the file's own folder.
local function tree_root(path)
  local home = vim.fs.normalize(vim.uv.os_homedir())
  if not path then
    return home
  end
  local root = vim.fs.root(path, ROOT_MARKERS)
  if root then
    return root
  end
  return vim.startswith(path, home .. "/") and home or vim.fs.dirname(path)
end

-- Whether path, below root, sits in or is a dot file.
local function is_hidden(path, root)
  if not path then
    return false
  end
  local relative = path:sub(#root + 2)
  return ("/" .. relative):find("/%.") ~= nil
end

-- Whether git ignores path.
local function is_ignored(path)
  if not path or vim.fn.executable("git") == 0 then
    return false
  end
  local result = vim.system({ "git", "check-ignore", "-q", path }, { cwd = vim.fs.dirname(path) }):wait()
  return result.code == 0
end

-- Writes bufnr to path; overwrite allows replacing another file.
local function write_buffer(bufnr, path, overwrite)
  local command = buffer_path(bufnr) == path and "write" or "saveas"
  if overwrite then
    command = command .. "!"
  end
  local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
    local target = vim.fn.bufnr(path)
    if target ~= -1 and target ~= bufnr and vim.api.nvim_buf_is_loaded(target) then
      if vim.bo[target].modified then
        error("Destination buffer has unsaved changes; save or discard them first", 0)
      end
      -- :saveas cannot take a loaded buffer's name, even with !.
      for _, win in ipairs(vim.fn.win_findbuf(target)) do
        vim.api.nvim_win_set_buf(win, bufnr)
      end
      vim.api.nvim_buf_delete(target, { unload = true })
    end
    vim.cmd(command .. " " .. vim.fn.fnameescape(path))
  end)
  if not ok then
    vim.notify("Save failed: " .. tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

-- The name with the cursor column just before its extension, if it has one.
local function name_cursor(name)
  local stem = name:match("^(.+)%.[^.]*$")
  return stem and #stem or #name
end

-- Opens the Save As dialog for bufnr (default: the current buffer). on_saved
-- runs once the buffer has been written.
function M.save_file(on_saved, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.tbl_contains({ "", "acwrite" }, vim.bo[bufnr].buftype) then
    vim.notify("This buffer cannot be saved to a file", vim.log.levels.WARN)
    return
  end
  local current = buffer_path(bufnr)
  local default = current and vim.fs.basename(current) or "Untitled"

  local width = math.min(MAX_WIDTH, vim.o.columns - 4)
  local list_height = math.max(5, math.floor(vim.o.lines * HEIGHT_RATIO))
  local top = math.max(0, math.floor((vim.o.lines - list_height - 5) / 2))
  local col = math.floor((vim.o.columns - width - 2) / 2)
  -- Where the dialog's popups are centred: over the field and the tree.
  local area = { row = top, col = col, width = width + 2, height = list_height + 5 }

  local field_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[field_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(field_buf, 0, -1, false, { default })
  local field_win, picker
  local field_col = name_cursor(default)
  local closing = false
  -- Whether Tab has given the tree focus, for every explorer key.
  local in_tree = false

  local help_win
  local help_ns = vim.api.nvim_create_namespace("save_file_help_keys")
  local function close_help()
    vim.on_key(nil, help_ns)
    if help_win and vim.api.nvim_win_is_valid(help_win) then
      vim.api.nvim_win_close(help_win, true)
    end
    help_win = nil
  end

  -- Lists the keys over the tree, leaving focus where it is. The next key
  -- only closes it.
  local function toggle_help()
    if help_win then
      return close_help()
    end
    local key_width = 0
    for _, entry in ipairs(HELP) do
      if entry[2] then
        key_width = math.max(key_width, #entry[1])
      end
    end
    local lines, marks = {}, {}
    for i, entry in ipairs(HELP) do
      if entry[2] then
        lines[i] = (" %-" .. key_width .. "s  %s"):format(entry[1], entry[2])
        marks[#marks + 1] = { i - 1, 1, 1 + key_width, "Special" }
      else
        lines[i] = entry[1] and (" " .. entry[1]) or ""
        if entry[1] then
          marks[#marks + 1] = { i - 1, 1, 1 + #entry[1], "Title" }
        end
      end
    end
    local help_width = 0
    for _, line in ipairs(lines) do
      help_width = math.max(help_width, vim.fn.strdisplaywidth(line) + 1)
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local ns = vim.api.nvim_create_namespace("save_file_help")
    for _, mark in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, mark[1], mark[2], { end_col = mark[3], hl_group = mark[4] })
    end
    help_win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      row = top + 4,
      col = col + math.max(0, math.floor((width - help_width) / 2)),
      width = math.min(help_width, width),
      height = math.min(#lines, list_height),
      border = "rounded",
      title = " Keys ",
      title_pos = "center",
      style = "minimal",
      focusable = false,
      zindex = 70,
    })
    vim.on_key(function(_, typed)
      if typed and typed ~= "" then
        vim.schedule(close_help)
        return ""
      end
    end, help_ns)
  end

  local function close()
    if closing then
      return
    end
    closing = true
    close_help()
    show_cursor()
    if picker and not picker.closed then
      picker:close()
    end
    if field_win and vim.api.nvim_win_is_valid(field_win) then
      vim.api.nvim_win_close(field_win, true)
    end
  end

  local function focus_field()
    if not (field_win and vim.api.nvim_win_is_valid(field_win)) then
      return
    end
    in_tree = false
    vim.api.nvim_set_current_win(field_win)
    -- Normal mode cannot put the cursor past the last character, so the end
    -- of the name is reached by appending instead.
    local line = vim.api.nvim_buf_get_lines(field_buf, 0, 1, false)[1] or ""
    if field_col >= #line then
      vim.cmd("startinsert!")
    else
      vim.api.nvim_win_set_cursor(field_win, { 1, field_col })
      vim.cmd.startinsert()
    end
  end

  -- The field keeps the cursor where it was.
  local function focus_tree()
    -- Insert mode leaves the cursor one past where normal mode will put it.
    field_col = vim.api.nvim_win_get_cursor(field_win)[2]
    vim.cmd.stopinsert()
    in_tree = true
    picker:focus("list")
  end

  local function leave_tree()
    vim.schedule(focus_field)
  end

  -- The folder of the selected entry, or the folder itself.
  local function selected_dir()
    local item = picker:current()
    if not item or not item.file then
      return picker:cwd()
    end
    local path = vim.fs.normalize(item.file)
    return (item.dir or vim.fn.isdirectory(path) == 1) and path or vim.fs.dirname(path)
  end

  -- Asks for one line of text; Enter gives it, Esc gives nil.
  local function prompt(title, on_text)
    local buf, win = popup({ "" }, title, popup_width("", title, width - 2), area)
    vim.wo[win].foldcolumn = "1"
    vim.wo[win].winhighlight = "FoldColumn:NormalFloat"
    local done = false
    local function finish(text)
      if done then
        return
      end
      done = true
      vim.cmd.stopinsert()
      pcall(vim.api.nvim_win_close, win, true)
      vim.schedule(function() on_text(text) end)
    end
    vim.keymap.set({ "i", "n" }, "<CR>", function()
      finish(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
    end, { buffer = buf, nowait = true })
    vim.keymap.set({ "i", "n" }, "<Esc>", function() finish(nil) end, { buffer = buf, nowait = true })
    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = buf,
      once = true,
      callback = function() finish(nil) end,
    })
    pcall(function() require("cmp").setup.buffer({ enabled = false }) end)
    vim.cmd.startinsert()
  end

  -- Puts focus back where it was before a popup: the tree after Tab, else
  -- the field.
  local function refocus()
    if in_tree and picker and not picker.closed then
      picker:focus("list")
    else
      focus_field()
    end
  end

  local function save()
    local name = vim.trim(vim.api.nvim_buf_get_lines(field_buf, 0, 1, false)[1] or "")
    local problem
    if name == "" then
      problem = "Enter a file name"
    elseif name == "." or name == ".." or name:find("/") then
      problem = "Enter a file name, not a path"
    end
    local path = not problem and vim.fs.joinpath(selected_dir(), name)
    if path and vim.fn.isdirectory(path) == 1 then
      problem = "A folder with that name already exists"
    end
    if problem then
      vim.notify(problem, vim.log.levels.WARN)
      return focus_field()
    end

    -- Every save is confirmed; replacing another file defaults to No.
    local overwrite = path ~= current and vim.uv.fs_stat(path) ~= nil
    local shown = vim.fn.fnamemodify(path, ":~")
    local question = overwrite and ("Overwrite %s?"):format(shown) or ("Save as %s?"):format(shown)
    ask(question, { default = overwrite and "no" or "yes", area = area }, function(choice)
      if choice ~= "yes" then
        return focus_field()
      end
      close()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) and write_buffer(bufnr, path, overwrite) and on_saved then
          on_saved()
        end
      end)
    end)
  end

  -- Takes the selected file's name into the field.
  local function take_name()
    local item = picker:current()
    if not (item and item.file) or item.dir then
      return
    end
    local name = vim.fs.basename(item.file)
    vim.api.nvim_buf_set_lines(field_buf, 0, -1, false, { name })
    field_col = name_cursor(name)
    if not in_tree then
      focus_field()
    end
  end

  -- Enter in the tree: a folder opens or closes, a file gives its name to
  -- the field and focus goes back there.
  local function tree_confirm()
    local item = picker:current()
    if not (item and item.file) then
      return
    elseif item.dir then
      require("snacks.explorer.tree"):toggle(item.file)
      require("snacks.explorer.actions").update(picker, { refresh = true })
      return
    end
    take_name()
    leave_tree()
  end

  -- Creates a folder inside the selected one and selects it.
  local function new_folder()
    local parent = selected_dir()
    if not in_tree then
      field_col = vim.api.nvim_win_get_cursor(field_win)[2]
    end
    prompt("New folder in " .. vim.fn.fnamemodify(parent, ":~"), function(name)
      name = name and vim.trim(name) or ""
      if name ~= "" then
        local path = vim.fs.joinpath(parent, name)
        if vim.fn.mkdir(path, "p") == 0 then
          vim.notify("Could not create " .. path, vim.log.levels.ERROR)
        else
          -- As the explorer's own add does: the parent is rescanned, then shown.
          local tree = require("snacks.explorer.tree")
          tree:open(path)
          tree:refresh(parent)
          require("snacks.explorer.actions").update(picker, { target = path })
        end
      end
      refocus()
    end)
  end

  -- Esc closes the help, then clears a search in the tree, as in the
  -- explorer, and only then cancels.
  local function tree_escape(p)
    if help_win then
      close_help()
    elseif p.explorer_search_match then
      p:action("explorer_nohl")
    else
      close()
    end
  end

  -- The tree opens at its root; the explorer reveals the current file itself.
  local root = tree_root(current)
  picker = Snacks.picker.explorer({
    title = "Save in",
    cwd = root,
    follow_file = current ~= nil,
    -- Hidden and ignored files stay out of the way, unless the file being
    -- saved is one of them and would otherwise not be revealed.
    hidden = is_hidden(current, root),
    ignored = is_ignored(current),
    focus = "list",
    -- Moving to the name field must not close the tree.
    auto_close = false,
    jump = { close = false },
    layout = {
      fullscreen = false,
      preview = false,
      hidden = { "input" },
      layout = {
        backdrop = false,
        box = "vertical",
        row = top + 3,
        col = col,
        width = width,
        height = list_height + 2,
        border = "rounded",
        title = "{title}",
        title_pos = "center",
        { win = "list", border = "none" },
      },
    },
    actions = {
      save_as_confirm = tree_confirm,
      save_as_escape = tree_escape,
      save_as_field = leave_tree,
      -- A click selects the entry; unless Tab went to the tree, typing goes
      -- on in the field.
      save_as_click = function()
        if not in_tree then
          vim.schedule(focus_field)
        end
      end,
    },
    win = {
      list = {
        keys = {
          -- The explorer forces its own confirm, so both ways of opening an
          -- entry are mapped instead.
          ["<CR>"] = "save_as_confirm",
          ["<2-LeftMouse>"] = "save_as_confirm",
          ["<LeftRelease>"] = "save_as_click",
          ["<Esc>"] = "save_as_escape",
          ["<a-?>"] = toggle_help,
          ["<a-n>"] = function() new_folder() end,
          ["<Tab>"] = "save_as_field",
          -- Nothing, as in the field; unmapped, the picker's own would focus
          -- the hidden filter box.
          ["<c-j>"] = noop,
          ["<c-k>"] = noop,
          -- These would leave the dialog: f swaps the tree for a file picker,
          -- the others open a file, terminal, grep or quickfix list, or move
          -- the tree into a split. Named as snacks spells them, so they
          -- replace its mappings; no-ops rather than false, since Vim's own
          -- <C-w>H/J/K/L would still turn the tree into a split.
          ["f"] = noop,
          ["<c-s>"] = noop,
          ["<c-v>"] = noop,
          ["<c-t>"] = noop,
          ["<S-CR>"] = noop,
          ["<leader>/"] = noop,
          ["<c-q>"] = noop,
          ["<c-w>H"] = noop,
          ["<c-w>J"] = noop,
          ["<c-w>K"] = noop,
          ["<c-w>L"] = noop,
        },
      },
    },
    on_show = function()
      field_win = vim.api.nvim_open_win(field_buf, true, {
        relative = "editor",
        row = top,
        col = col,
        width = width,
        height = 1,
        border = "rounded",
        title = " Save as ",
        title_pos = "center",
        style = "minimal",
        zindex = 60,
      })
      vim.wo[field_win].wrap = false
      -- A one-column fold column pads the name off the border, in the
      -- field's own colour.
      vim.wo[field_win].foldcolumn = "1"
      vim.wo[field_win].winhighlight = "FoldColumn:NormalFloat"
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(field_win),
        once = true,
        callback = function() vim.schedule(close) end,
      })
      -- The tree and its box take the look of every float, as the field
      -- and popups have: NormalFloat's dark and FloatBorder's border,
      -- instead of the editor's background and snacks' border. Through a
      -- group of its own with NormalFloat's colours: inside snacks'
      -- highlights NormalFloat points back at its group, which ends at the
      -- editor's. Snacks sets them again as it shows and redraws the tree,
      -- so they are added back each time.
      local float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
      vim.api.nvim_set_hl(0, "SaveFileTree", { fg = float.fg, bg = float.bg })
      local looks = {
        [picker.list.win.win] = { Normal = "SaveFileTree", NormalNC = "SaveFileTree", NormalFloat = "SaveFileTree" },
        [picker.layout.root.win] = {
          Normal = "SaveFileTree",
          NormalNC = "SaveFileTree",
          NormalFloat = "SaveFileTree",
          FloatBorder = "FloatBorder",
          FloatTitle = "FloatTitle",
        },
      }
      local function restyle()
        for win, look in pairs(looks) do
          if vim.api.nvim_win_is_valid(win) and not vim.wo[win].winhighlight:find("SaveFileTree", 1, true) then
            Snacks.util.wo(win, { winhighlight = Snacks.util.winhl(vim.wo[win].winhighlight, look) })
          end
        end
      end
      local list_win = picker.list.win.win
      local restyle_au = vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "winhighlight",
        callback = function()
          if not vim.api.nvim_win_is_valid(list_win) then
            return true
          end
          vim.schedule(restyle)
        end,
      })
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(list_win),
        once = true,
        callback = function() pcall(vim.api.nvim_del_autocmd, restyle_au) end,
      })
      restyle()
      -- The selected row shows where the tree is; the cursor would only
      -- add a block at its start.
      vim.api.nvim_create_autocmd("WinEnter", {
        buffer = picker.list.win.buf,
        callback = hide_cursor,
      })
      vim.api.nvim_create_autocmd("WinLeave", {
        buffer = picker.list.win.buf,
        callback = show_cursor,
      })
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(picker.list.win.win),
        once = true,
        callback = function() vim.schedule(close) end,
      })
      focus_field()
    end,
  })

  -- Runs a tree action from the field. CursorMoved only fires in the
  -- current window, so the tree's search highlight is told of the move.
  local function tree(action)
    return function()
      picker:action(action)
      pcall(vim.api.nvim_exec_autocmds, "CursorMoved", { buffer = picker.list.win.buf })
    end
  end

  local function map(lhs, fn)
    vim.keymap.set({ "i", "n" }, lhs, fn, { buffer = field_buf, nowait = true })
  end
  map("<CR>", save)
  map("<Esc>", function() tree_escape(picker) end)
  map("<Tab>", focus_tree)
  -- The arrows move in the tree, as in the explorer; <C-h>/<C-l> move the
  -- cursor in the name instead.
  map("<Down>", tree("list_down"))
  map("<Up>", tree("list_up"))
  map("<Right>", tree("explorer_expand"))
  map("<Left>", tree("explorer_close"))
  for lhs, keys in pairs({ ["<C-h>"] = { "<Left>", "h" }, ["<C-l>"] = { "<Right>", "l" } }) do
    vim.keymap.set({ "i", "n" }, lhs, function()
      return vim.api.nvim_get_mode().mode == "i" and keys[1] or keys[2]
    end, { buffer = field_buf, expr = true })
  end
  -- Would otherwise start a second line or a digraph.
  map("<C-j>", noop)
  map("<C-k>", noop)
  map("<C-d>", tree("list_scroll_down"))
  map("<C-u>", tree("list_scroll_up"))
  map("<PageDown>", function() picker.list:scroll(picker.list.state.height) end)
  map("<PageUp>", function() picker.list:scroll(-picker.list.state.height) end)
  -- Names cannot hold a slash, so / is free to search the tree. The search
  -- runs from the tree, whose prompt keys live there, and stays there once
  -- confirmed so n/N reach the next hits; cancelled, it returns here.
  map("/", function()
    focus_tree()
    vim.schedule(function()
      picker:action("explorer_search")
      if not picker.explorer_search_match then
        focus_field()
      end
    end)
  end)
  map("<C-n>", tree("explorer_search_next"))
  map("<C-p>", tree("explorer_search_prev"))
  map("<C-y>", take_name)
  map("<A-n>", new_folder)
  map("<A-h>", tree("toggle_hidden"))
  map("<A-i>", tree("toggle_ignored"))
  map("<A-?>", toggle_help)
  pcall(function()
    vim.api.nvim_buf_call(field_buf, function()
      require("cmp").setup.buffer({ enabled = false })
    end)
  end)
end

return M
