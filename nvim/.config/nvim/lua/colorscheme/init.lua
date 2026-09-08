-- Remembers the colorscheme picked with <leader>ft and applies it at startup.
local M = {}

local STATE = vim.fn.stdpath('state') .. '/colorscheme'
local FALLBACK = 'onedark'

-- The colorscheme saved by the last switch, or nil when there is none.
local function get_colorscheme()
  local f = io.open(STATE, 'r')
  if not f then
    return nil
  end
  local name = vim.trim(f:read('*l') or '')
  f:close()
  return name ~= '' and name or nil
end

-- Records a colorscheme as the one to start with.
local function save_colorscheme(name)
  local f = io.open(STATE, 'w')
  if f then
    f:write(name)
    f:close()
  end
end

-- Applies the saved colorscheme, falling back when it is not installed.
-- Called after lazy has loaded the theme plugins, so their colours are found.
function M.restore()
  local name = get_colorscheme()
  if not (name and pcall(vim.cmd.colorscheme, name)) then
    vim.cmd.colorscheme(FALLBACK)
  end
  -- On exit rather than on ColorScheme: the theme picker previews as it goes,
  -- so every step of the preview fires that event.
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('colorscheme_save', { clear = true }),
    callback = function()
      if vim.g.colors_name then
        save_colorscheme(vim.g.colors_name)
      end
    end,
  })
end

return M
