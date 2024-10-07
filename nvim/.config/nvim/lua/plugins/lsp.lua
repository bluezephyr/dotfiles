-- LSP settings
-- LSP Configuration & Plugins
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    {
      'j-hui/fidget.nvim',
      tag = "legacy",
      event = "LspAttach",
      opts = {}
    },
  },

  config = function()
    --  This function gets run when an LSP connects to a particular buffer.
    local on_attach = function(_, bufnr)
      local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

      nmap('<leader>sF', '<cmd>Format<CR>', 'Format current file')

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
      nmap('<leader>ss', function()
        require('telescope.builtin').lsp_document_symbols({ symbol_width = 100 })
      end, 'Document Symbols')
      nmap('<leader>sf', function()
        require('telescope.builtin').lsp_document_symbols({ symbols = 'function', symbol_width = 100 })
      end, 'Document Functions')

      -- LSP Workspace functionality
      nmap('<leader>sw', require('telescope.builtin').lsp_workspace_symbols, 'Workspace Symbols')
      nmap('<leader>sW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Dynamic Workspace Symbols')
      nmap('<leader>sA', vim.lsp.buf.add_workspace_folder, 'Workspace Add Folder')
      nmap('<leader>sR', vim.lsp.buf.remove_workspace_folder, 'Workspace Remove Folder')
      nmap('<leader>sL', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, 'Workspace List Folders')

      -- Clang specific
      nmap('<A-o>', ':ClangdSwitchSourceHeader<CR>', 'Switch source/header file')

      -- Create a command `:Format` local to the LSP buffer
      vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        if vim.lsp.buf.format then
          vim.lsp.buf.format()
        elseif vim.lsp.buf.formatting then
          vim.lsp.buf.formatting()
        end
      end, { desc = 'Format current buffer with LSP' })
    end

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
      'marksman',
      'taplo',
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
