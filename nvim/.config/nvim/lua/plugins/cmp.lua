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
      local function directory_context()
        local kind = vim.fn.getcmdcompltype()
        return vim.fn.getcmdtype() == ":" and (kind == "dir" or kind == "dir_in_path")
      end
      local directory_pattern = [=[\%(\\.\|[^[:blank:]]\)*]=]

      cmp.register_source("directories", {
        is_available = directory_context,
        get_trigger_characters = function() return { " ", "/", "." } end,
        get_keyword_pattern = function() return directory_pattern end,
        complete = function(_, params, callback)
          local line = params.context.cursor_before_line
          local argument = vim.fn.matchstr(line, directory_pattern .. "$")
          local parent = argument:match("^.*/") or ""
          local hidden = line:sub(1, #line - #argument) .. parent .. ".*"
          local items, seen = {}, {}
          -- Query afresh at each level: cmp-cmdline retains parent candidates.
          for _, query in ipairs({ line, hidden }) do
            for _, path in ipairs(vim.fn.getcompletion(query, "cmdline")) do
              local name = path:gsub("/+$", ""):match("[^/]+$")
              if name ~= "." and name ~= ".." and not seen[path] then
                seen[path] = true
                local escaped = vim.fn.fnameescape(path)
                items[#items + 1] = {
                  label = path,
                  insertText = escaped,
                  filterText = escaped,
                  kind = cmp.lsp.CompletionItemKind.Folder,
                }
              end
            end
          end
          callback({ items = items, isIncomplete = true })
        end,
      })

      local next_item = cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }), { "i", "c" })
      local prev_item = cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }), { "i", "c" })
      local confirm = cmp.mapping.confirm({ select = true })
      local completion_mapping = {
        ["<Down>"] = next_item,
        ["<Up>"] = prev_item,
        ["<C-j>"] = next_item,
        ["<C-k>"] = prev_item,
        ["<Tab>"] = {
          i = confirm,
          c = function()
            if not cmp.confirm({ select = true }) then cmp.complete() end
          end,
        },
        -- Command-line Enter runs the command with the selected entry, or as
        -- typed when none is selected; Tab and <C-y> only accept it.
        ["<CR>"] = {
          i = confirm,
          c = function(fallback)
            if not cmp.confirm({}, function()
              vim.api.nvim_feedkeys(vim.keycode("<CR>"), "n", false)
            end) then
              fallback()
            end
          end,
        },
        ["<C-y>"] = cmp.mapping(confirm, { "i", "c" }),
      }

      cmp.setup({
        preselect = cmp.PreselectMode.None,
        completion = { completeopt = "menu,menuone,noinsert" },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert(vim.tbl_extend("force", completion_mapping, {
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
        })),
        formatting = {
          format = lspkind.cmp_format({
            -- mode = "symbol_text",
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = '...',
            -- symbol_map = { Codeium = "", },
            menu = ({
              -- codeium = '[Codeium]',
              nvim_lsp = '[Lsp]',
              luasnip = '[Luasnip]',
              buffer = '[File]',
              path = '[Path]',
            })
          }),
        },
        sources = {
          -- { name = "codeium",  priority = 1000 },
          { name = "nvim_lsp", priority = 500 },
          { name = "luasnip",  priority = 15 },
          { name = "buffer",   priority = 1 },
          { name = "path" },
        },
        window = {
          completion = {
            border = {
              { "󱐋", "WarningMsg" },
              { "─", "FloatBorder" },
              { "╮", "FloatBorder" },
              { "│", "FloatBorder" },
              { "╯", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╰", "FloatBorder" },
              { "│", "FloatBorder" },
            },
            scrollbar = false,
            winblend = 0,
          },
          documentation = {
            border = {
              { "󰙎", "DiagnosticHint" },
              { "─", "FloatBorder" },
              { "╮", "FloatBorder" },
              { "│", "FloatBorder" },
              { "╯", "FloatBorder" },
              { "─", "FloatBorder" },
              { "╰", "FloatBorder" },
              { "│", "FloatBorder" },
            },
            scrollbar = false,
            winblend = 0,
          },
        }
      })
      local function other_cmdline_entries()
        return not directory_context()
      end
      cmp.setup.cmdline(":", {
        completion = {
          autocomplete = { cmp.TriggerEvent.InsertEnter, cmp.TriggerEvent.TextChanged },
          -- Nothing selected at first, so Enter runs the command as typed.
          completeopt = "menu,menuone,noinsert,noselect",
        },
        mapping = cmp.mapping.preset.cmdline(vim.tbl_extend("force", completion_mapping, {
          -- The cmdline preset maps C-n/C-p to cmp selection by default.
          -- Use fallback to restore Vim's default: command history navigation.
          ["<C-n>"] = { c = function(fallback) fallback() end },
          ["<C-p>"] = { c = function(fallback) fallback() end },
        })),
        sources = {
          { name = "directories", keyword_length = 0 },
          { name = "path", option = { trailing_slash = true }, entry_filter = other_cmdline_entries },
          {
            name = "cmdline",
            option = { treat_trailing_slash = false },
            trigger_characters = { " ", ".", "#", "-", "/" },
            entry_filter = other_cmdline_entries,
          },
        },
      })
      -- No popup for searches, so a single Enter runs the search.
      cmp.setup.cmdline({ "/", "?" }, { enabled = false })
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
