local M = {}

function M.save_file()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    vim.ui.input({ prompt = "Save as: " }, function(input)
      if input and input ~= "" then
        vim.cmd("write " .. vim.fn.fnameescape(input))
      end
    end)
  else
    vim.cmd("write")
  end
end

return M
