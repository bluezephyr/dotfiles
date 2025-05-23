return {
  -- TODO: Evaluate https://github.com/Saghen/blink.cmp
  {
    "onsails/lspkind-nvim",
    config = function()
      require('lspkind').setup()
    end
  },
  {
    -- Autocompletion
    -- https://github.com/hrsh7th/nvim-cmp
    -- https://github.com/hrsh7th/cmp-nvim-lsp
    -- https://github.com/L3MON4D3/LuaSnip
    -- https://github.com/saadparwaiz1/cmp_luasnip
    "hrsh7th/nvim-cmp",
    event = "VeryLazy",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "onsails/lspkind-nvim",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      'L3MON4D3/LuaSnip',
    },
    config = function()
      local luasnip = require("luasnip")
      local cmp = require("cmp")
      local lspkind = require('lspkind')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<CR>'] = cmp.mapping.confirm({ select = false }),
          ['<Tab>'] = cmp.mapping.confirm({ select = true }),
          ['<S-CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-CR>'] = cmp.mapping.confirm({ select = true }),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
        }),
        formatting = {
          format = lspkind.cmp_format({
            -- mode = "symbol_text",
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = '...',
            symbol_map = { Codeium = "", },
            menu = ({
              codeium = '[Codeium]',
              nvim_lsp = '[Lsp]',
              luasnip = '[Luasnip]',
              buffer = '[File]',
              path = '[Path]',
            })
          }),
        },
        sources = {
          { name = "codeium",  priority = 1000 },
          { name = "nvim_lsp", priority = 500 },
          { name = "luasnip",  priority = 15 },
          { name = "buffer",   priority = 1 },
          { name = "path" },
        },
        window = {
          completion = {
            border = {
              { "󱐋", "WarningMsg" },
              { "─", "Comment" },
              { "╮", "Comment" },
              { "│", "Comment" },
              { "╯", "Comment" },
              { "─", "Comment" },
              { "╰", "Comment" },
              { "│", "Comment" },
            },
            scrollbar = false,
            winblend = 0,
          },
          documentation = {
            border = {
              { "󰙎", "DiagnosticHint" },
              { "─", "Comment" },
              { "╮", "Comment" },
              { "│", "Comment" },
              { "╯", "Comment" },
              { "─", "Comment" },
              { "╰", "Comment" },
              { "│", "Comment" },
            },
            scrollbar = false,
            winblend = 0,
          },
        }
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources {
          { name = "path" },
          { name = "cmdline" },
        },
      })
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip").setup()
      require("luasnip.loaders.from_vscode").lazy_load()
    end
  },
  {
    "rafamadriz/friendly-snippets"
  },
}
