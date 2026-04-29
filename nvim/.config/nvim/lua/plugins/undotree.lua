-- https://github.com/mbbill/undotree
-- Manually cloned to ~/.local/share/nvim/site/pack/*/opt/undotree/ and loaded
-- via the built-in :packadd mechanism instead of lazy.nvim.
vim.cmd.packadd('nvim.undotree')

return {
  vim.keymap.set("n", "<leader>tu", "<cmd>Undotree<cr>", { desc = "[T]oggle [U]ndotree" })
}
