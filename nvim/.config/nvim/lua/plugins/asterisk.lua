-- https://github.com/haya14busa/vim-asterisk
return {
  "haya14busa/vim-asterisk",

  config = function()
    local keymap = vim.api.nvim_set_keymap

    keymap("n", "z*", "<Plug>(asterisk-z*)", {})
    keymap("n", "gz*", "<Plug>(asterisk-gz*)", {})
    keymap("n", "*", "<Plug>(asterisk-z*)<Plug>(is-nohl-1)", {})
    keymap("n", "g*", "<Plug>(asterisk-gz*)<Plug>(is-nohl-1)", {})
    keymap("n", "#", "<Plug>(asterisk-gz*)<Plug>(is-nohl-1)", {})

    keymap("v", "z*", "<Plug>(asterisk-z*)", {})
    keymap("v", "gz*", "<Plug>(asterisk-gz*)", {})
    keymap("v", "*", "<Plug>(asterisk-z*)<Plug>(is-nohl-1)", {})
    keymap("v", "g*", "<Plug>(asterisk-gz*)<Plug>(is-nohl-1)", {})
    keymap("v", "#", "<Plug>(asterisk-gz*)<Plug>(is-nohl-1)", {})

    --vim.g["asterisk#keeppos"] = 1
  end
}
