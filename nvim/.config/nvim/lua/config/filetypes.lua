vim.filetype.add({
  pattern = {
    [vim.fn.expand('~/.local/rfc') .. '/.*%.txt'] = 'rfc',
  },
})
