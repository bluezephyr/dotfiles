local M = {}

local bufnr = nil
local winid = nil

function M.get_buf()
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    return bufnr
  end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "[Build Log]")
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  return bufnr
end

function M.toggle()
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, false)
    winid = nil
    return
  end
  local buf = M.get_buf()
  vim.cmd("split")
  winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, buf)
  vim.api.nvim_set_option_value("wrap", false, { win = winid })
  vim.cmd("normal! G")
end

function M.append(lines)
  local buf = M.get_buf()
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  if winid and vim.api.nvim_win_is_valid(winid) then
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(winid, { line_count, 0 })
  end
end

function M.clear()
  local buf = M.get_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
end

return M
