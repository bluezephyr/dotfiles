-- Autocommand to automatically close any empty buffers when another buffer is opened
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local current_buf = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        if vim.api.nvim_buf_get_name(buf) == "" and vim.api.nvim_buf_get_option(buf, "buftype") == "" then
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          if #lines == 1 and lines[1] == "" then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end
    end
  end
})
