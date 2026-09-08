-- LSP settings
-- LSP Configuration & Plugins
-- See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/

-- Popups ---------------------------------------------------------------------
-- Closing is shared, in lua/popup. This is the part that is LSP's own.
local popup = require('popup')

-- open_floating_preview records its window on the buffer it was opened from.
local function popup_win()
  local win = vim.b.lsp_floating_preview
  if win and vim.api.nvim_win_is_valid(win) then
    return win
  end
end

-- The request is answered asynchronously, so the window appears after the call.
local function show_popup(open)
  local win, origin = popup.open(open, popup_win)
  if win then
    popup.bind_close_keys(win, origin)
  end
end

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
    -- Shipped by nvim-lspconfig and unwanted here; the enable below covers only
    -- the listed servers, so this is insurance against anything else enabling it.
    vim.lsp.enable('gitlab_duo', false)

    --  This function gets run when an LSP connects to a particular buffer.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end


        map('<leader>sF', '<cmd>Format<CR>', 'Format current file')

        map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
        map('gt', vim.lsp.buf.type_definition, 'Goto Type definition')
        -- map('gr', require('telescope.builtin').lsp_references, 'Goto References')
        map('gI', vim.lsp.buf.implementation, 'Goto Implementation')
        map('gh', ":LspClangdSwitchSourceHeader<CR>", 'Switch header/source')

        -- See `:help K` for why this keymap
        map('K', function() show_popup(vim.lsp.buf.hover) end, 'Hover Documentation')

        map('<leader>sr', vim.lsp.buf.rename, 'Rename')
        map('<leader>sa', vim.lsp.buf.code_action, 'Code Action')
        map('<leader>sk', function() show_popup(vim.lsp.buf.signature_help) end, 'Signature Documentation')
        map('<leader>sd', function() show_popup(vim.diagnostic.open_float) end, 'Show Diagnostics')

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

    -- Setup mason so it can manage external tooling
    require('mason').setup()

    -- Servers to configure and enable. See `:help lspconfig-all` for the
    -- pre-configured ones nvim-lspconfig ships.
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
            -- Ignore Lua_LS's noisy `missing-fields` warnings
            diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    -- nvim-cmp supports additional completion capabilities, so broadcast that
    -- to every server.
    vim.lsp.config('*', {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })

    for name, config in pairs(servers) do
      vim.lsp.config(name, config)
    end
    vim.lsp.enable(vim.tbl_keys(servers))

    local ensure_installed = vim.tbl_keys(servers)
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Only for :LspInstall and the mason/lspconfig name translation. Enabling
    -- is done above: automatic_enable would also start every other installed
    -- package that happens to ship an LSP config, stylua among them.
    require('mason-lspconfig').setup {
      automatic_enable = false,
    }
  end
}
