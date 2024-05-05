-- Useful plugin to show you pending keybinds.
-- https://github.com/folke/which-key.nvim
return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  opts = {
    window = {
      border = "rounded",
      position = "bottom"-- bottom, top
    },
    show_help = false,
    triggers_nowait = {
      -- marks
      "`",
      "'",
      "g`",
      "g'",
      -- registers
      '@',
      '"',
      "<c-r>",
      -- spelling
      "z=",
    },
  },
}
