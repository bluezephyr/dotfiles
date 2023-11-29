-- LSP settings
-- LSP Configuration & Plugins
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    {
      'j-hui/fidget.nvim',
      tag = "legacy",
      event = "LspAttach",
      opts = {}
    },

    -- Additional lua configuration, makes nvim stuff amazing!
    'folke/neodev.nvim',
  },

  config = function()
    --  This function gets run when an LSP connects to a particular buffer.
    local on_attach = function(_, bufnr)
      -- NOTE: Remember that lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself
      -- many times.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

      nmap('<leader>sf', '<cmd>Format<CR>', 'Format current file')

      nmap('gd', vim.lsp.buf.definition, 'Goto Definition')
      nmap('gD', vim.lsp.buf.declaration, 'Goto Declaration')
      nmap('gr', require('telescope.builtin').lsp_references, 'Goto References')
      nmap('gI', vim.lsp.buf.implementation, 'Goto Implementation')

      -- See `:help K` for why this keymap
      nmap('K', vim.lsp.buf.hover, 'Hover Documentation')

      nmap('<leader>sr', vim.lsp.buf.rename, 'Rename')
      nmap('<leader>sa', vim.lsp.buf.code_action, 'Code Action')
      nmap('<leader>sk', vim.lsp.buf.signature_help, 'Signature Documentation')
      nmap('<leader>sd', vim.diagnostic.open_float, 'Show Diagnostics')
      nmap('<leader>ss', require('telescope.builtin').lsp_document_symbols, 'Document Symbols')

      vim.keymap.set('n', '<leader>st', function()
        require('telescope.builtin').lsp_document_symbols { symbols = { 'function' } }
      end, { desc = 'Find All Files' })


      -- LSP Workspace functionality
      nmap('<leader>sw', require('telescope.builtin').lsp_workspace_symbols, 'Workspace Symbols')
      nmap('<leader>sW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Dynamic Workspace Symbols')
      nmap('<leader>sA', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
      nmap('<leader>sR', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')
      nmap('<leader>sL', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, 'Workspace List Folders')

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        if vim.lsp.buf.format then
          vim.lsp.buf.format()
        elseif vim.lsp.buf.formatting then
          vim.lsp.buf.formatting()
        end
      end, { desc = 'Format current buffer with LSP' })
    end

    -- Setup neovim lua configuration
    require('neodev').setup()

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Setup mason so it can manage external tooling
    require('mason').setup()

    -- Enable the following language servers
    -- Feel free to add/remove any LSPs that you want here. They will automatically be installed
    local servers = {
      'clangd',
      'jsonls',
      'rust_analyzer',
      'lua_ls',
      'pyright',
      'tsserver',
      'marksman',
    }

    -- Ensure the servers above are installed
    require('mason-lspconfig').setup {
      ensure_installed = servers,
    }

    for _, lsp in ipairs(servers) do
      require('lspconfig')[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end

    -- Turn on lsp status information
    require('fidget').setup()

    -- Example custom configuration for lua
    --
    -- Make runtime files discoverable to the server
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')
  end
}
-- From which_key:
--
--     l = {
--         name = "LSP",
--         a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
--         d = {
--             "<cmd>Telescope lsp_document_diagnostics<cr>",
--             "Document Diagnostics",
--         },
--         w = {
--             "<cmd>Telescope lsp_workspace_diagnostics<cr>",
--             "Workspace Diagnostics",
--         },
--         f = { "<cmd>lua vim.lsp.buf.formatting()<cr>", "Format" },
--         i = { "<cmd>LspInfo<cr>", "Info" },
--         I = { "<cmd>LspInstallInfo<cr>", "Installer Info" },
--         j = {
--             "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
--             "Next Diagnostic",
--         },
--         k = {
--             "<cmd>lua vim.lsp.diagnostic.goto_prev()<cr>",
--             "Prev Diagnostic",
--         },
--         l = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
--         q = { "<cmd>lua vim.lsp.diagnostic.set_loclist()<cr>", "Quickfix" },
--         r = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
--         s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
--         S = {
--             "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
--             "Workspace Symbols",
--         },
