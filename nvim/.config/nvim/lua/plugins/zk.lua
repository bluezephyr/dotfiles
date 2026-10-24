-- Notes in the zk notebook, with the zk LSP for links, tags and backlinks.
-- https://github.com/zk-org/zk-nvim

-- Snacks options shared by the zk pickers: the query starts as pattern and can
-- be edited, and <C-e> hands whatever is typed to on_create. The pattern is
-- lowercased so it matches regardless of case and <C-e> suggests a lowercase
-- title, so near-duplicates like nisse and Nisse are not created.
local function snacks_opts(pattern, on_create, desc)
  local function create(picker)
    local title = picker.input:get()
    picker:close()
    if title ~= "" then
      on_create(title)
    end
  end

  return {
    pattern = pattern and vim.fn.tolower(pattern),
    -- Opens even without matches, so a note can still be created with <C-e>.
    show_empty = true,
    actions = { zk_create = create },
    win = { input = { keys = { ["<c-e>"] = { "zk_create", mode = { "n", "i" }, desc = desc } } } },
  }
end

-- Like `zk edit --interactive`: <CR> opens a note, <C-e> creates one from the query.
local function edit_or_create(options, pattern)
  require("zk").edit(options or { sort = { "modified" } }, {
    title = "Zk Edit or Create",
    snacks_picker = snacks_opts(pattern, function(title)
      require("zk.commands").get("ZkNew")({ title = title })
    end, "create note"),
  })
end

-- Live search over the notebook's note contents.
local function search_notes()
  vim.ui.input({ prompt = "Search: " }, function(query)
    if query and query ~= "" then
      edit_or_create({ sort = { "modified" }, match = { query } })
    end
  end)
end

local function search_notes_by_word_under_cursor()
  local word = vim.fn.expand("<cword>")
  if word ~= "" then
    edit_or_create(nil, word)
  end
end

-- Notes with the tag under the cursor, or all tags when it is not on one.
local function search_notes_by_tag_under_cursor()
  local tag = vim.fn.expand("<cWORD>"):match("#([%w_/-]+)")
  if tag then
    edit_or_create({ tags = { tag } })
  else
    require("zk.commands").get("ZkTags")()
  end
end

-- Links text at location to a note picked with text as query; <C-e> creates a
-- note from the query and links to that instead. Without text, the query starts
-- empty and the link gets the note's title.
local function insert_link(text, location)
  local util = require("zk.util")
  local api = require("zk.api")
  local bufnr = vim.api.nvim_get_current_buf()
  local notebook_path = util.resolve_notebook_path(bufnr)
  local root = vim.fs.root(bufnr, ".zk")
  -- Not api.link: that uses the first zk client the plugin found, which may
  -- serve another notebook and then does not have this buffer open.
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "zk" })[1]
  if not client then
    vim.notify("zk is not attached to this buffer", vim.log.levels.WARN)
    return
  end

  local function link_to_note(path)
    client:request("workspace/executeCommand", {
      command = "zk.link",
      arguments = { notebook_path, { path = path, location = location, title = text } },
    }, function(err)
      assert(not err, tostring(err))
    end, bufnr)
  end

  require("zk").pick_notes({ notebook_path = notebook_path, sort = { "modified" } }, {
    title = "Zk Insert Link",
    multi_select = false,
    snacks_picker = snacks_opts(text, function(title)
      api.new(notebook_path, { title = title, edit = false }, function(err, note)
        assert(not err, tostring(err))
        -- new returns an absolute path, but link only finds notebook-relative ones.
        link_to_note(vim.fs.relpath(root, note.path))
      end)
    end, "create note and insert link"),
  }, function(note)
    link_to_note(note.path)
  end)
end

local function insert_link_for_selection()
  local util = require("zk.util")
  insert_link(util.get_selected_text(), util.get_lsp_location_from_selection())
end

-- Links the word under the cursor, or inserts a link after the cursor when it
-- is not on a word.
local function insert_link_at_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local char = vim.fn.matchstr(vim.api.nvim_get_current_line(), "\\%" .. (col + 1) .. "c.")
  if vim.fn.match(char, "\\k") == 0 then
    vim.cmd("normal! viw\27")
    insert_link_for_selection()
  else
    insert_link(nil, require("zk.util").get_lsp_location_from_caret())
  end
end

return {
  "zk-org/zk-nvim",
  cmd = { "ZkNew", "ZkNotes", "ZkTags", "ZkBacklinks", "ZkLinks", "ZkIndex", "ZkEditOrCreate", "ZkInsertLinkAtSelectionEdit" },
  opts = {
    picker = "snacks_picker",
    -- Attaching is left to vim.lsp.enable('zk') in plugins/lsp.lua, so it does
    -- not depend on this plugin having been loaded. The plugin reuses that
    -- client if one is attached when it is first used, else starts its own.
    lsp = { auto_attach = { enabled = false } },
  },
  config = function(_, opts)
    require("zk").setup(opts)
    require("zk.commands").add("ZkInsertLinkAtSelectionEdit", insert_link_for_selection, { needs_selection = true })
    vim.api.nvim_create_user_command("ZkEditOrCreate", function()
      edit_or_create()
    end, {})
  end,
  keys = {
    { "<leader>zf", edit_or_create, desc = "zk: Edit or create note" },
    { "<leader>zo","<Cmd>ZkBuffers { sort = { 'modified' } }<CR>", desc = "zk: List Find notes" },
    { "<leader>zw", search_notes_by_word_under_cursor, desc = "zk: Find notes matching word under cursor" },
    { "<leader>zt", search_notes_by_tag_under_cursor, desc = "zk: Notes with tag under cursor, or all tags" },
    { "<leader>zg", search_notes, desc = "zk: Grep in notes" },
    { "<leader>zb", "<Cmd>ZkBacklinks<CR>", desc = "zk: Backlinks" },
    { "<leader>zl", "<Cmd>ZkLinks<CR>", desc = "zk: Links" },
    { "<leader>zi", "<Cmd>ZkIndex<CR>", desc = "zk: Index notebook" },
    { "<leader>zn", insert_link_at_cursor, desc = "zk: Insert link for word under cursor" },
    { "<leader>zn", ":'<,'>ZkInsertLinkAtSelectionEdit {}<CR>", mode = "v", desc = "zk: Insert link for selection" },
    { "<leader>zg", ":'<,'>ZkMatch<CR>", mode = "v", desc = "zk: Notes matching selection" },
  },
}
