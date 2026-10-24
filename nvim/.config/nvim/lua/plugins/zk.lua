-- Notes in the zk notebook, with the zk LSP for links, tags and backlinks.
-- https://github.com/zk-org/zk-nvim

-- Snacks options shared by the zk pickers: the query starts as pattern and can
-- be edited, and <C-e> hands whatever is typed to on_create.
local function snacks_opts(pattern, on_create, desc)
  local function create(picker)
    local title = picker.input:get()
    picker:close()
    if title ~= "" then
      on_create(title)
    end
  end

  return {
    pattern = pattern,
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

local function search_notes_by_tag_under_cursor()
  local tag = vim.fn.expand("<cWORD>"):match("#([%w_/-]+)")
  if tag then
    edit_or_create({ tags = { tag } })
  else
    vim.notify("No tag under cursor", vim.log.levels.INFO)
  end
end

-- Links the selection to a note picked with the selection as query; <C-e>
-- creates a note from the query and links to that instead.
local function insert_link_for_selection()
  local util = require("zk.util")
  local api = require("zk.api")
  local selected_text = util.get_selected_text()
  local location = util.get_lsp_location_from_selection()
  local notebook_path = util.resolve_notebook_path(0)

  local function link_to_note(path)
    api.link(path, location, notebook_path, { title = selected_text }, function(err)
      assert(not err, tostring(err))
    end)
  end

  require("zk").pick_notes({ notebook_path = notebook_path, sort = { "modified" } }, {
    title = "Zk Insert Link",
    multi_select = false,
    snacks_picker = snacks_opts(selected_text, function(title)
      api.new(notebook_path, { title = title, edit = false }, function(err, note)
        assert(not err, tostring(err))
        link_to_note(note.path)
      end)
    end, "create note and insert link"),
  }, function(note)
    link_to_note(note.path)
  end)
end

return {
  "zk-org/zk-nvim",
  cmd = { "ZkNew", "ZkNotes", "ZkTags", "ZkBacklinks", "ZkLinks", "ZkIndex", "ZkEditOrCreate", "ZkInsertLinkAtSelectionEdit" },
  opts = {
    picker = "snacks_picker",
    -- Attaching is left to vim.lsp.enable('zk') in plugins/lsp.lua, so it does
    -- not depend on this plugin having been loaded. The plugin reuses that client.
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
    { "<leader>zt", search_notes_by_tag_under_cursor, desc = "zk: Find notes with tag under cursor" },
    { "<leader>zT", "<Cmd>ZkTags<CR>", desc = "zk: Tags" },
    { "<leader>zg", search_notes, desc = "zk: Grep in notes" },
    { "<leader>zb", "<Cmd>ZkBacklinks<CR>", desc = "zk: Backlinks" },
    { "<leader>zl", "<Cmd>ZkLinks<CR>", desc = "zk: Links" },
    { "<leader>zi", "<Cmd>ZkIndex<CR>", desc = "zk: Index notebook" },
    { "<leader>zL", "viw:ZkInsertLinkAtSelectionEdit {}<CR>", desc = "zk: Insert link for word under cursor" },
    { "<leader>zL", ":'<,'>ZkInsertLinkAtSelectionEdit {}<CR>", mode = "v", desc = "zk: Insert link for selection" },
    { "<leader>zg", ":'<,'>ZkMatch<CR>", mode = "v", desc = "zk: Notes matching selection" },
  },
}
