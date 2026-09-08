-- Shared popup behaviour. Each plugin config keeps a Popups section for the
-- part that is its own -- which window is its popup, and how it should open --
-- and calls in here for the part that is the same everywhere.
local M = {}

M.CLOSE_KEYS = { '<Esc>', 'q' }

-- Removes the close keys from a buffer.
local function drop_close_keys(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  for _, key in ipairs(M.CLOSE_KEYS) do
    pcall(vim.keymap.del, 'n', key, { buffer = buf })
  end
end

-- Binds the close keys inside the popup and on the buffer it came from. The
-- origin buffer keeps them only while the popup is open, so q goes back to
-- recording a macro once it closes.
function M.bind_close_keys(win, origin)
  local origin_buf = vim.api.nvim_win_get_buf(origin)
  for _, key in ipairs(M.CLOSE_KEYS) do
    vim.keymap.set('n', key, '<cmd>quit!<cr>',
      { buffer = vim.api.nvim_win_get_buf(win), silent = true, desc = 'Close popup' })
    vim.keymap.set('n', key, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = origin_buf, silent = true, desc = 'Close popup' })
  end
  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    once = true,
    callback = function()
      drop_close_keys(origin_buf)
    end,
  })
end

-- Popups arrive only once their content has been fetched, so opening one means
-- waiting for its window to appear. Returns that window and the one it was
-- opened from, or nil when it never arrives.
function M.open(open, find)
  local origin = vim.api.nvim_get_current_win()
  open()
  local win
  vim.wait(1000, function()
    win = find()
    return win ~= nil
  end, 20)
  return win, origin
end

return M
