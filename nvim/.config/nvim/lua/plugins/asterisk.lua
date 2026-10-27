-- * and # search for the word or selection without moving the cursor.
-- https://github.com/haya14busa/vim-asterisk
return {
  "haya14busa/vim-asterisk",
  keys = {
    { "*", "<Plug>(asterisk-z*)", mode = { "n", "x" } },
    { "#", "<Plug>(asterisk-z#)", mode = { "n", "x" } },
    { "g*", "<Plug>(asterisk-gz*)", mode = { "n", "x" } },
  },
}
