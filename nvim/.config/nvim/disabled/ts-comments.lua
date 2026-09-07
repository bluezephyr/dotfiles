-- Plugin for the built in commenting https://github.com/folke/ts-comments.nvim
-- Disabled on trial: Neovim's own ftplugins already give the same
-- commentstring for every language used here. See README.md.
return {
  "folke/ts-comments.nvim",
  event = "VeryLazy",
  opts = {},
}
