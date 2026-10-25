-- https://github.com/petertriho/nvim-scrollbar
return {
  'petertriho/nvim-scrollbar',
  -- v2 replaces v1 on main on 2026-11-16; drop the branch then.
  branch = 'refactor/v2',
  opts = {
    scrollbar = {
      thumb = { highlight = { bg = 'Gray' } },
    },
  },
}
