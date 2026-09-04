-- Reference trees that <leader>fi searches as one list.
local reference_dirs = { "~/index", "~/.local/rfc" }

-- rg stops at 500 columns by default; the last flag wins.
local grep_args = { "--max-columns=4096" }

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

local function confirm_option(picker, item)
  picker:close()
  set_option(item, "local")
end

local function confirm_option_global(picker, item)
  picker:close()
  set_option(item, "global")
end

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
  Snacks.picker.grep({ dirs = { name }, hidden = true, args = grep_args })
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

local function pick_reference()
  Snacks.picker.files({ dirs = reference_dirs, hidden = true, follow = true })
end

-- Named so the dashboard reaches the same picker as the keymap.
vim.api.nvim_create_user_command('PickReference', pick_reference, { desc = 'Reference (index and RFCs)' })

-- Matches what the buffers picker lists: every listed buffer but this one.
local function other_buffers()
  local current = vim.api.nvim_get_current_buf()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      count = count + 1
    end
  end
  return count
end

-- Nothing to switch to needs no message, and a single candidate needs no list.
local function pick_buffers()
  if other_buffers() == 0 then
    return
  end
  Snacks.picker.buffers({ current = false, auto_confirm = true })
end

local function pick_lsp_locations()
  Snacks.picker.pick({ title = "Locations", multi = lsp_locations })
end

return {
  -- https://github.com/folke/snacks.nvim
  "folke/snacks.nvim",
  opts = {
    picker = {
      layout = { cycle = true, preset = "vertical", fullscreen = true },

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
          },
        },
      },
    },
  },
  keys = {
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
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Files",
    },
    {
      "<leader>f.",
      function()
        Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
      end,
      desc = "Files in current folder",
    },
    {
      "<leader>fg",
      function()
        Snacks.picker.grep({ hidden = true, args = grep_args })
      end,
      desc = "Live Grep",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep Word",
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
      pick_buffers,
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
