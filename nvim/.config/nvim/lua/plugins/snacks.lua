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
    dashboard = { enabled = true },
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
          require('snacks').dashboard.open()
        end)
      end,
      desc = "Open Snacks Dashboard",
    },
  },
}
