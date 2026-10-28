-- Reference trees that <leader>fi searches as one list.
local reference_dirs = { "~/index", "~/.local/rfc" }

-- Locations that <leader>sf collects into a single list.
local lsp_locations = {
  "lsp_definitions",
  "lsp_declarations",
  "lsp_implementations",
  "lsp_type_definitions",
  "lsp_references",
}

-- There is no options source, so this picker brings its own items.
local function option_items()
  local items = {}
  for name, info in pairs(vim.api.nvim_get_all_options_info()) do
    local ok, value = pcall(vim.api.nvim_get_option_value, name, {})
    if ok then
      items[#items + 1] = {
        text = name .. " " .. tostring(value),
        name = name,
        value = value,
        type = info.type,
        preview = { text = vim.inspect(info), ft = "lua" },
      }
    end
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  return items
end

-- Renders one option row, colouring booleans by value.
local function format_option(item)
  local value_hl = "Comment"
  if item.value == true then
    value_hl = "DiagnosticOk"
  elseif item.value == false then
    value_hl = "DiagnosticError"
  end
  return {
    { Snacks.picker.util.align(item.name, 22), "Identifier" },
    { tostring(item.value), value_hl },
  }
end

-- The prompt hands back a string; the option wants its own type.
local function parse_option(item, input)
  if item.type == "boolean" then
    return input == "true" or input == "1"
  elseif item.type == "number" then
    return tonumber(input)
  end
  return input
end

-- Prompts for a new value and applies it in the given scope.
local function set_option(item, scope)
  local prompt = ("%s (%s) = "):format(item.name, scope)
  vim.ui.input({ prompt = prompt, default = tostring(item.value) }, function(input)
    if not input then
      return
    end
    local value = parse_option(item, input)
    if value == nil then
      vim.notify(item.name .. " expects a number", vim.log.levels.WARN)
      return
    end
    local ok, err = pcall(vim.api.nvim_set_option_value, item.name, value, { scope = scope })
    if ok then
      vim.notify(("%s = %s"):format(item.name, tostring(value)))
    else
      vim.notify(tostring(err), vim.log.levels.ERROR)
    end
  end)
end

-- Applies the picked option to the current buffer or window.
local function confirm_option(picker, item)
  picker:close()
  set_option(item, "local")
end

-- Applies the picked option globally.
local function confirm_option_global(picker, item)
  picker:close()
  set_option(item, "global")
end

-- Picks a Neovim option to change.
local function pick_options()
  Snacks.picker.pick({
    title = "Options",
    finder = option_items,
    format = format_option,
    confirm = confirm_option,
    actions = { option_set_global = confirm_option_global },
    win = { input = { keys = { ["<a-cr>"] = { "option_set_global", mode = { "i", "n" } } } } },
  })
end

-- Live grep restricted to this file, rather than a fuzzy pass over its lines.
local function grep_curbuf()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    vim.notify("No file in this buffer", vim.log.levels.WARN)
    return
  end
  Snacks.picker.grep({ dirs = { name } })
end

-- Live grep starting from the word under the cursor or the visual selection,
-- escaped so it matches literally; whole wraps it in \b to match whole words.
local function grep_word(whole)
  Snacks.picker.grep({
    search = function(picker)
      local text = picker:word():match("[^\n]*"):gsub("[%.%+%*%?%(%)|%[%]{}%^%$\\]", "\\%0")
      return whole and "\\b" .. text .. "\\b" or text
    end,
  })
end

-- Whether the last explorer showed hidden and ignored files (H and I), so the
-- next one opens the same way.
local explorer_toggles = {}

-- The explorer only reveals files inside its cwd, so a file from elsewhere
-- (e.g. a zk note) opens it at that file's project instead.
local function explorer(opts)
  opts = vim.tbl_extend("force", explorer_toggles, opts or {})
  local file = vim.api.nvim_buf_get_name(0)
  if vim.fn.filereadable(file) == 1 and not vim.startswith(file, vim.fn.getcwd() .. "/") then
    opts.cwd = vim.fs.root(0, { ".zk", ".git" }) or vim.fs.dirname(file)
  end
  Snacks.explorer(opts)
end

-- Snacks' own sidebar, which stays open beside the files it opens.
local function explorer_split()
  explorer({
    layout = { preset = "sidebar", fullscreen = false, preview = false },
    auto_close = false,
    jump = { close = false },
  })
end

-- The window whose title shows the search status.
local function explorer_status_win(picker)
  return picker.layout.root:has_border() and picker.layout.root or picker.input.win
end

-- Gives the hit on the cursor row CurSearch, as in a buffer. The row is
-- spelled out, since a \%.l match keeps showing on the row the cursor left.
local function explorer_set_cur_match(picker)
  local match = picker.explorer_search_match
  if not match then
    return
  end
  local win = picker.list.win.win
  if match.cur_id then
    vim.fn.matchdelete(match.cur_id, win)
  end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  local pattern = ("\\%%%dl"):format(row) .. match.pattern
  match.cur_id = vim.fn.matchadd("CurSearch", pattern, 11, -1, { window = win })
end

-- Highlights pattern in the list, or clears the highlight when it is nil.
-- Window matches survive the list buffer being redrawn while scrolling.
local function explorer_set_match(picker, pattern)
  local win = picker.list.win.win
  local match = picker.explorer_search_match
  if match then
    vim.fn.matchdelete(match.id, win)
    vim.fn.matchdelete(match.cur_id, win)
  end
  picker.explorer_search_match = pattern
    and { id = vim.fn.matchadd("Search", pattern, 10, -1, { window = win }), pattern = pattern }
  explorer_set_cur_match(picker)
  -- CursorMoved covers moves in the list, but not those made from the
  -- search prompt, which update the match themselves.
  if pattern and not picker.explorer_cursor_autocmd then
    picker.explorer_cursor_autocmd = vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = picker.list.win.buf,
      callback = function() explorer_set_cur_match(picker) end,
    })
  end
end

-- Search the result items, not the buffer, which only holds on-screen rows.
local function explorer_search_jump(picker, direction, pattern, cursor, preview)
  if pattern == "" then
    return
  end
  local list = picker.list
  local status_win = explorer_status_win(picker)
  local ignorecase = vim.o.ignorecase and not (vim.o.smartcase and pattern:find("%u"))
  local search_pattern = (ignorecase and "\\c" or "\\C") .. pattern
  local ok, regex = pcall(vim.regex, search_pattern)
  if not ok then
    if not preview then
      vim.notify(tostring(regex), vim.log.levels.WARN)
    end
    return
  end
  picker.explorer_title = picker.explorer_title or vim.deepcopy(status_win.opts.title)
  explorer_set_match(picker, search_pattern)
  local count = list:count()
  local hits, total = {}, 0
  for index = 1, count do
    local item = list:get(index)
    local name = item.file and vim.fs.basename(item.file) or item.text
    if regex:match_str(name) then
      total = total + 1
      hits[index] = total
    end
  end
  local step = list.reverse and -direction or direction
  for offset = 1, count do
    local index = cursor + offset * step
    if not vim.o.wrapscan and (index < 1 or index > count) then
      break
    end
    index = (index - 1) % count + 1
    if hits[index] then
      local current = list.reverse and total - hits[index] + 1 or hits[index]
      list:view(index)
      explorer_set_cur_match(picker)
      local status = ("[%d/%d] /%s"):format(current, total, pattern)
      status_win:set_title(status)
      if not preview then
        vim.api.nvim_echo({ { status, "Search" } }, false, {})
      end
      return
    end
  end
  status_win:set_title(("[0/%d] /%s"):format(total, pattern))
  if not preview then
    vim.notify("Pattern not found: " .. pattern, vim.log.levels.INFO)
  end
end

-- Like :nohlsearch; the explorer stays open (q closes it).
local function explorer_nohl(picker)
  if not picker.explorer_search_match then
    return
  end
  explorer_set_match(picker, nil)
  explorer_status_win(picker):set_title(picker.explorer_title)
end

-- Opens a closed folder and moves to its first entry, if it shows any. While
-- filtering, confirm reveals the folder in the tree instead.
local function explorer_expand(picker, item)
  if not (item and item.dir and not item.open) then
    return
  elseif picker.input.filter.meta.searching then
    return picker:action("confirm")
  end
  require("snacks.explorer.tree"):open(item.file)
  picker.list:set_target()
  picker:find({
    on_done = function()
      for index = 1, picker.list:count() do
        if vim.fs.dirname(picker.list:get(index).file) == item.file then
          picker.list:view(index)
          return
        end
      end
    end,
  })
end

local function explorer_search(picker, direction, prompt)
  local list = picker.list
  local cursor, top = list.cursor, list.top
  local original = picker:current()
  local pattern = vim.fn.getreg("/")
  if not prompt then
    return explorer_search_jump(picker, direction, pattern, cursor)
  end
  local status_win = explorer_status_win(picker)
  local title = vim.deepcopy(status_win.opts.title)
  local previous_match = picker.explorer_search_match and picker.explorer_search_match.pattern
  local function restore()
    explorer_set_match(picker, previous_match)
    local index = cursor
    for i, item in ipairs(picker:items()) do
      if original and item.file == original.file then
        index = i
        break
      end
    end
    list:view(index, top)
    explorer_set_cur_match(picker)
    status_win:set_title(title)
  end
  local navigated = false
  local changed = vim.api.nvim_create_autocmd("CmdlineChanged", {
    pattern = "@",
    callback = function()
      navigated = false
      restore()
      explorer_search_jump(picker, direction, vim.fn.getcmdline(), list.cursor, true)
      vim.cmd.redraw()
    end,
  })
  local function action(name)
    return function() picker:action(name) end
  end
  local function hit(step)
    return function() explorer_search_jump(picker, direction * step, vim.fn.getcmdline(), list.cursor, true) end
  end
  -- Arrows move through the tree; <C-g>/<C-t> go to the next and previous
  -- hit, as with 'incsearch' in a buffer.
  local keys = {
    ["<Up>"] = action("list_up"),
    ["<Down>"] = action("list_down"),
    ["<Left>"] = action("explorer_close"),
    ["<Right>"] = action("explorer_expand"),
    ["<C-g>"] = hit(1),
    ["<C-t>"] = hit(-1),
  }
  for key, fn in pairs(keys) do
    vim.keymap.set("c", key, function()
      navigated = true
      fn()
      explorer_set_cur_match(picker)
      vim.cmd.redraw()
    end, { buffer = list.win.buf })
  end
  vim.fn.inputsave()
  local ok, input = pcall(vim.fn.input, { prompt = "/", cancelreturn = "\27" })
  vim.fn.inputrestore()
  for key in pairs(keys) do
    vim.keymap.del("c", key, { buffer = list.win.buf })
  end
  vim.api.nvim_del_autocmd(changed)
  if not ok or input == "\27" then
    return restore()
  end
  pattern = input ~= "" and input or pattern
  if pattern ~= "" then
    vim.fn.setreg("/", pattern)
    vim.fn.histadd("search", pattern)
  end
  if not navigated then
    restore()
    explorer_search_jump(picker, direction, pattern, list.cursor)
  end
end

-- Items carry a cwd-relative path; the register should hold the whole one.
local function yank_path(picker, item)
  local path = Snacks.picker.util.path(item)
  if not path then
    return Snacks.picker.actions.yank(picker, item, { reg = "+" })
  end
  vim.fn.setreg("+", path)
  Snacks.notify(("Yanked to register `+`:\n```\n%s\n```"):format(path), { title = "Snacks Picker" })
end

-- Picks a file from the reference trees.
local function pick_reference()
  Snacks.picker.files({ dirs = reference_dirs, follow = true })
end

-- Named so the dashboard reaches the same picker as the keymap.
vim.api.nvim_create_user_command('PickReference', pick_reference, { desc = 'Reference (index and RFCs)' })

-- Picks from every kind of LSP location at once.
local function pick_lsp_locations()
  Snacks.picker.pick({ title = "Locations", multi = lsp_locations })
end

-- Lists the paths changed by a commit against its first parent (including
-- root commits), rather than checking out the commit as git_log normally does.
local function commit_files_quickfix(picker, item)
  picker:close()
  if not item then
    return
  end
  local result = vim.system({
    "git", "-C", item.cwd, "diff-tree", "--root", "-m", "--first-parent",
    "--no-commit-id", "--name-only", "-M", "-r", "-z", item.commit,
  }):wait()
  if result.code ~= 0 then
    vim.notify("Could not list commit files: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
    return
  end
  local items = {}
  for _, path in ipairs(vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })) do
    items[#items + 1] = { filename = vim.fs.joinpath(item.cwd, path), lnum = 1, text = path }
  end
  if #items == 0 then
    vim.notify("No files changed in " .. item.commit, vim.log.levels.WARN)
    return
  end
  vim.fn.setqflist({}, " ", { title = "Commit " .. item.commit, items = items })
  vim.cmd.copen()
end

return {
  -- https://github.com/folke/snacks.nvim
  "folke/snacks.nvim",
  opts = {
    picker = {
      layout = { cycle = true, preset = "vertical", fullscreen = true },

      -- Snacks shows R when regex is off; show it when regex is on instead.
      toggles = { regex = { icon = "R", value = true } },

      sources = {
        -- Every file list and grep, the dashboard's included, also covers dot
        -- files. rg stops at 500 columns by default; the last flag wins.
        files = { hidden = true },
        grep = { hidden = true, args = { "--max-columns=4096" } },
        -- Fullscreen like the other pickers instead of Snacks' sidebar; opening
        -- a file closes it, the way neo-tree in the current window did.
        explorer = {
          layout = { preset = "vertical", preview = false },
          auto_close = true,
          jump = { close = true },
          diagnostics = false,
          hidden = true,
          on_close = function(picker)
            explorer_toggles = { hidden = picker.opts.hidden, ignored = picker.opts.ignored }
          end,
          actions = {
            explorer_expand = explorer_expand,
            explorer_nohl = explorer_nohl,
            explorer_search = function(picker) explorer_search(picker, 1, true) end,
            explorer_search_next = function(picker) explorer_search(picker, 1) end,
            explorer_search_prev = function(picker) explorer_search(picker, -1) end,
          },
          win = {
            -- Esc leaves the filter for the list, to move around with hjkl.
            input = { keys = { ["<esc>"] = { "focus_list", mode = { "n", "i" } } } },
            -- Search without changing the filter; `i` still reaches the filter.
            list = { keys = {
              ["<Esc>"] = "explorer_nohl",
              ["<Left>"] = "explorer_close",
              ["<Right>"] = "explorer_expand",
              -- Opens folders only; Enter opens files.
              ["l"] = "explorer_expand",
              ["/"] = "explorer_search",
              ["n"] = "explorer_search_next",
              ["N"] = "explorer_search_prev",
            } },
          },
        },
      },

      actions = {
        yank_path = yank_path,
        yank_entry = { action = "yank", reg = "+" },
      },

      win = {
        input = {
          -- Names the key that lists all the others, on the prompt's own border.
          footer_keys = { "<a-?>" },
          footer_pos = "right",
          keys = {
            -- One press leaves, rather than dropping into normal mode first.
            ["<esc>"] = { "cancel", mode = { "n", "i" } },
            ["<c-y>"] = { "yank_entry", mode = { "n", "i" } },
            -- The full path when the item is a file, the entry text otherwise.
            ["<a-y>"] = { "yank_path", mode = { "n", "i" } },
            -- `?` lists the keys too, but only in normal mode; the input starts in insert.
            ["<a-?>"] = { "toggle_help_input", mode = { "n", "i" }, desc = "help" },
            -- <C-j>/<C-k> move between the windows, input above list above
            -- preview, as they do between splits, wrapping around at the ends.
            -- Unmapped, they would reach the split navigation and leave the
            -- picker. <C-n>/<C-p> still move the selection.
            ["<c-j>"] = { "focus_list", mode = { "n", "i" } },
            ["<c-k>"] = { "focus_preview", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            -- The same key where the list has focus, as in the explorer.
            ["<a-?>"] = { "toggle_help_list", desc = "help" },
            ["<c-j>"] = "focus_preview",
            ["<c-k>"] = "focus_input",
          },
        },
        preview = { keys = { ["<c-j>"] = "focus_input", ["<c-k>"] = "focus_list" } },
      },
    },
  },
  keys = {
    {
      "\\",
      explorer,
      desc = "File explorer",
    },
    {
      "|",
      explorer_split,
      desc = "File explorer in a split",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>fh",
      function()
        Snacks.picker.help()
      end,
      desc = "Help tags",
    },
    {
      "<leader>fa",
      function()
        Snacks.picker.commands()
      end,
      desc = "Commands",
    },
    {
      "<leader>fd",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>fq",
      function()
        Snacks.picker.qflist()
      end,
      desc = "Quickfix list",
    },
    {
      "<leader>fo",
      pick_options,
      desc = "Vim Options",
    },
    {
      "<leader>fm",
      function()
        Snacks.picker.man()
      end,
      desc = "Manpages",
    },
    {
      "<leader>fc",
      function()
        Snacks.picker.resume()
      end,
      desc = "Continue (resume last search)",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent files",
    },
    {
      "<leader>fs",
      function()
        Snacks.picker.search_history()
      end,
      desc = "Search History",
    },
    {
      "<leader>fi",
      pick_reference,
      desc = "Index (and RFCs)",
    },
    {
      "<leader>ft",
      function()
        Snacks.picker.colorschemes()
      end,
      desc = "Themes",
    },
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Files",
    },
    {
      "<leader>f.",
      function()
        -- The word under the cursor, or the selection in visual mode.
        Snacks.picker.files({ pattern = function(picker) return picker:word() end })
      end,
      mode = { "n", "x" },
      desc = "Files matching word or selection",
    },
    {
      "<leader>f/",
      function()
        Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
      end,
      desc = "Files in current folder",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live Grep",
    },
    {
      "<leader>fg",
      function()
        grep_word(false)
      end,
      mode = "x",
      desc = "Grep selection",
    },
    {
      "<leader>fw",
      function()
        grep_word(true)
      end,
      mode = { "n", "x" },
      desc = "Grep whole word or selection",
    },
    {
      "<leader>fz",
      function()
        Snacks.picker.pickers()
      end,
      desc = "Pickers",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>'",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>ä",
      function()
        Snacks.picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>/",
      grep_curbuf,
      desc = "Search in current buffer",
    },
    {
      "<leader><leader>",
      function()
        -- Sorted by last use, so the alternate buffer comes first.
        Snacks.picker.buffers({ current = false })
      end,
      desc = "Buffers",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git status",
    },
    {
      "<leader>gl",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git log",
    },
    {
      "<leader>gf",
      function()
        Snacks.picker.git_log({ confirm = commit_files_quickfix })
      end,
      desc = "Git commit files in quickfix",
    },

    -- LSP keymaps
    {
      "<leader>ss",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "LSP: Document Symbols",
    },
    {
      "<leader>sw",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "LSP: Workspace Symbols",
    },
    {
      "<leader>si",
      function()
        Snacks.picker.lsp_incoming_calls()
      end,
      desc = "LSP: Incoming Calls",
    },
    {
      "<leader>sf",
      pick_lsp_locations,
      desc = "LSP: Find all locations",
    },
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "LSP: Definitions",
    },
    {
      "gr",
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "LSP: References",
    },
    {
      "<leader>sD",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "LSP: Show All Diagnostics",
    },
    {
      "z=",
      function()
        -- `fullscreen` has to go, or the suggestions cover the whole editor.
        Snacks.picker.spelling({ layout = { preset = "vscode", fullscreen = false } })
      end,
      desc = "Spelling suggestions",
    },
  },
}
