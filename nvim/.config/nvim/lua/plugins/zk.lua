-- Notes in the zk notebook, with the zk LSP for links, tags and backlinks.
-- https://github.com/zk-org/zk-nvim

-- Live search over the notebook's note contents.
local function search_notes()
  vim.ui.input({ prompt = "Search: " }, function(query)
    if query and query ~= "" then
      require("zk.commands").get("ZkNotes")({ sort = { "modified" }, match = { query } })
    end
  end)
end

-- Creates a note titled with whatever is typed in the picker.
local function create_from_query(picker)
  local title = picker.input:get()
  picker:close()
  if title ~= "" then
    require("zk.commands").get("ZkNew")({ title = title })
  end
end

-- Like `zk edit --interactive`: <CR> opens a note, <C-e> creates one from the query.
local function edit_or_create()
  require("zk").edit({ sort = { "modified" } }, {
    title = "Zk Edit or Create",
    snacks_picker = {
      actions = { zk_create = create_from_query },
      win = { input = { keys = { ["<c-e>"] = { "zk_create", mode = { "n", "i" }, desc = "create note" } } } },
    },
  })
end

return {
  "zk-org/zk-nvim",
  cmd = { "ZkNew", "ZkNotes", "ZkTags", "ZkBacklinks", "ZkLinks", "ZkIndex" },
  opts = {
    picker = "snacks_picker",
    -- Attaching is left to vim.lsp.enable('zk') in plugins/lsp.lua, so it does
    -- not depend on this plugin having been loaded. The plugin reuses that client.
    lsp = { auto_attach = { enabled = false } },
  },
  config = function(_, opts)
    require("zk").setup(opts)
  end,
  keys = {
    { "<leader>zn", edit_or_create, desc = "zk: Edit or create note" },
    { "<leader>zf","<Cmd>ZkNotes { sort = { 'modified' } }<CR>", desc = "zk: Find notes" },
    { "<leader>zo","<Cmd>ZkBuffers { sort = { 'modified' } }<CR>", desc = "zk: List Find notes" },
    { "<leader>zt", "<Cmd>ZkTags<CR>", desc = "zk: Tags" },
    { "<leader>zg", search_notes, desc = "zk: Grep in notes" },
    { "<leader>zb", "<Cmd>ZkBacklinks<CR>", desc = "zk: Backlinks" },
    { "<leader>zl", "<Cmd>ZkLinks<CR>", desc = "zk: Links" },
    { "<leader>zi", "<Cmd>ZkIndex<CR>", desc = "zk: Index notebook" },
    { "<leader>zg", ":'<,'>ZkMatch<CR>", mode = "v", desc = "zk: Notes matching selection" },
  },
}
