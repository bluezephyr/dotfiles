return {
  -- https://github.com/folke/snacks.nvim
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  config = function(_, opts)
    require("snacks").setup(opts)
    -- Workaround for https://github.com/folke/snacks.nvim/issues/2539
    -- Patch win:dim() to floor dimension values, avoiding
    -- "Invalid 'height': Number is not integral" errors.
    local Win = require("snacks.win")
    local orig_dim = Win.dim
    if orig_dim then
      Win.dim = function(self, ...)
        local ret = orig_dim(self, ...)
        if ret then
          for _, key in ipairs({ "height", "width", "row", "col" }) do
            if type(ret[key]) == "number" then
              ret[key] = math.floor(ret[key])
            end
          end
        end
        return ret
      end
    end
  end,
  opts = {
    picker = {
      layout = {
        cycle = true,
        preset = "vertical",
        fullscreen = true,
      },
    },
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    -- bigfile = { enabled = true },
    bufdelete = { enabled = true },

    dashboard = {
      enabled = true,
      preset = {
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "i", desc = "Index", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.expand('~/index'), follow = true, hidden = true, title = 'Index'})" },
          { icon = " ", key = "n", desc = "New File", action = ":ene" },
          { icon = " ", key = "g", desc = "Grep Text", action = ":lua Snacks.dashboard.pick('live_grep')", },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')", },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})", },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil, },
          { icon = "󰟾 ", key = "M", desc = "Mason", action = ":Mason" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { text = {
            { "  ", hl = "DiagnosticOk" },
            { "v"},
            { vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch, hl = "Error" },
          },
          align = "center",
          padding = 1,
        },
      },
    },
    -- explorer = { enabled = true },
    -- indent = { enabled = true },
    -- input = { enabled = true },
    -- picker = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
      style = "fancy",
    },
    -- quickfile = { enabled = true },
    -- scope = { enabled = true },
    -- scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = false },
  },
  keys = {
    {
      "<leader>n",
      function()
        require("snacks").picker.notifications()
      end,
      desc = "Notification History",
    },
    {
      "<leader>q",
      function()
        require("snacks").bufdelete()
      end,
      desc = "Close buffer",
    },
    {
      "<leader>r",
      function()
        pcall(function()
          require("snacks").dashboard.open()
        end)
      end,
      desc = "Open Snacks Dashboard",
    },
  },
}
