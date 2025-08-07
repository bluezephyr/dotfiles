-- LSP settings
-- LSP Configuration & Plugins
-- See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs to stdpath for neovim
    -- NOTE: Must be loaded before dependants
    { 'williamboman/mason.nvim', opts = {} },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP
    { 'j-hui/fidget.nvim',       opts = {} },

    -- https://github.com/folke/lazydev.nvim
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = "luvit-meta/library", words = { "vim%.uv" } },
        },
      },
    },

    -- https://github.com/Bilal2453/luvit-meta
    { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings

  },
  config = function()
    --  This function gets run when an LSP connects to a particular buffer.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- More keymaps are located in the fzflua.lua file

        map('<leader>sf', '<cmd>Format<CR>', 'Format current file')

        map('gd', vim.lsp.buf.definition, 'Goto Definition')
        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
        map('gt', vim.lsp.buf.type_definition, 'Goto Type definition')
        -- map('gr', require('telescope.builtin').lsp_references, 'Goto References')
        map('gI', vim.lsp.buf.implementation, 'Goto Implementation')

        -- See `:help K` for why this keymap
        map('K', vim.lsp.buf.hover, 'Hover Documentation')

        map('<leader>sr', vim.lsp.buf.rename, 'Rename')
        map('<leader>sa', vim.lsp.buf.code_action, 'Code Action')
        map('<leader>sk', vim.lsp.buf.signature_help, 'Signature Documentation')
        map('<leader>sd', vim.diagnostic.open_float, 'Show Diagnostics')

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(0, 'Format', function(_)
          if vim.lsp.buf.format then
            vim.lsp.buf.format()
          elseif vim.lsp.buf.formatting then
            vim.lsp.buf.formatting()
          end
        end, { desc = 'Format current buffer with LSP' })

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end
      end
    })

    -- Use some nice look and feel
    vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
      config = config
          or {
            border = {
              { "╭", "Comment" },
              { "─", "Comment" },
              { "╮", "Comment" },
              { "│", "Comment" },
              { "╯", "Comment" },
              { "─", "Comment" },
              { "╰", "Comment" },
              { "│", "Comment" },
            },
          }
      config.focus_id = ctx.method
      if not (result and result.contents) then
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      return vim.lsp.util.open_floating_preview(markdown_lines, "markdown", config)
    end

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    -- local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Setup mason so it can manage external tooling
    require('mason').setup()
    local lspconfig = require("lspconfig")

    -- See `:help lspconfig-all` for a list of all the pre-configured LSPs
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim

    -- Enable the following language servers
    local servers = {
      clangd = {},
      jsonls = {},
      pyright = {},
      marksman = {},
      taplo = {},
      rust_analyzer = {},
      bashls = {},
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    ---@diagnostic disable-next-line: missing-fields
    require('mason-lspconfig').setup {
      ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
      automatic_installation = false,
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for ts_ls)
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
    -- Turn on lsp status information
    -- require('fidget').setup()

    -- Example custom configuration for lua
    --
    -- Make runtime files discoverable to the server
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')
  end
}
