return {
  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        -- Fuzzy Finder Algorithm which requires local dependencies to be built.
        -- Only load if `make` is available. Make sure you have the system
        -- requirements installed.
        'nvim-telescope/telescope-fzf-native.nvim',
        build = "make"
        -- cond = function()
        --   return vim.fn.executable 'make' == 1
        -- end,
      },
      -- TODO: Add Telescope file browser
      -- https://github.com/nvim-telescope/telescope-file-browser.nvim
      -- { "nvim-telescope/telescope-file-browser.nvim" }
      -- },
    },

    config = function()
      -- Enable telescope fzf native, if installed
      pcall(require('telescope').load_extension, 'fzf')
      -- pcall(require('telescope').load_extension, 'file_browser')

      require('telescope').setup({
        defaults = {
          path_display = { "smart" },
          mappings = {
            i = {
              ['<C-j>'] = require("telescope.actions").move_selection_next,
              ['<C-k>'] = require "telescope.actions".move_selection_previous,
              ['<C-x>'] = require("telescope.actions").delete_buffer,
              ['<ESC>'] = require("telescope.actions").close,
            },
            n = {
              ['<C-j>'] = require("telescope.actions").move_selection_next,
              ['<C-k>'] = require "telescope.actions".move_selection_previous,
              ['<C-x>'] = require('telescope.actions').delete_buffer,
            },
          },
          results_title = false,
          sorting_strategy = "ascending",
          layout_strategy = 'vertical',
          layout_config = {
            center = {
              width = 0.8,
              height = 0.9,
            },
          },
          pickers = {
            find_files = {
              theme = "dropdown",
              previewer = true,
            }
          },
          -- }, extensions = {
          --     file_browser = {
          --         -- theme = "dropdown",
          --         -- disables netrw and use telescope-file-browser in its place
          -- hijack_netrw = true,
          -- },
        },
      })

      vim.keymap.set('n', '<leader>t', "<cmd>Telescope<CR>", { desc = 'Telescope' })

      vim.keymap.set("n", "<C-q>", function()
        require("telescope.builtin").quickfix()
        vim.cmd(":cclose")
      end, { desc = "Open Quickfix" })

      vim.keymap.set('n', '<leader><space>', function()
        require('telescope.builtin').buffers(require('telescope.themes').get_dropdown { previewer = false,
          layout_config = {
            width = 0.8,
            height = 25
          }
        })
      end, { desc = 'Buffers' })

      vim.keymap.set('n', '<leader>fa', function()
        require('telescope.builtin').find_files { find_command = { 'fd', '-HI' } }
      end, { desc = 'Find All Files' })

      vim.keymap.set('n', '<leader>f.', function()
        require('telescope.builtin').find_files { cwd = vim.fn.expand('%:p:h'), find_command = { 'fd' } }
      end, { desc = 'Find Files Relative Current' })

      vim.keymap.set('n', '<leader>fm', function()
        require('telescope.builtin').man_pages { sections = { 'ALL' } }
      end, { desc = 'Man Pages' })

      vim.keymap.set('n', '<leader>/', require('telescope.builtin').current_buffer_fuzzy_find,
        { desc = 'Fuzzy search in current buffer' })

      vim.keymap.set('n', '<leader>h', require('telescope.builtin').oldfiles, { desc = 'Recent Files' })
      vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find Files' })
      vim.keymap.set('n', '<c-p>', require('telescope.builtin').find_files, { desc = 'Find Files' })
      vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Help' })
      vim.keymap.set('n', '<leader>fk', require('telescope.builtin').keymaps, { desc = 'Keymaps' })
      vim.keymap.set('n', '<leader>fc', require('telescope.builtin').commands, { desc = 'Commands' })
      vim.keymap.set('n', '<leader>fo', require('telescope.builtin').vim_options, { desc = 'Vim Options' })

      vim.keymap.set('n', '<leader>*', require('telescope.builtin').grep_string, { desc = 'Find Current Word' })
      vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = 'Find text' })
      vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = 'Find Diagnostics' })

      vim.keymap.set('n', '<leader>fs', function()
        require('telescope.builtin').live_grep { vimgrep_arguments = { 'rg', '--color=never', '--no-heading',
          '--with-filename', '--line-number', '--column', '--smart-case', '-.', '--no-ignore', '--glob=!.git/*' } }
      end, { desc = 'Find text (all)' })

      -- Git commands
      vim.keymap.set('n', '<leader>gs', require('telescope.builtin').git_status, { desc = 'Git Status' })
      vim.keymap.set('n', '<leader>gc', require('telescope.builtin').git_commits, { desc = 'Git Commits' })
    end
  },
}
--   -- vim.keymap.set('n', '<leader>/', function()
--   --     require('telescope.builtin').current_buffer_fuzzy_find({ layout_strategy = "center", previewer = false })
--   -- end, { desc = '[/] Fuzzily search in current buffer]' })
--
--   -- vim.keymap.set('n', '<leader>e', require('telescope').extensions.file_browser.file_browser, { desc = 'File [E]xplorer' })
--
--   vim.keymap.set('n', '<leader>ss', function()
--     require('telescope.builtin').live_grep { vimgrep_arguments = { 'rg', '--color=never', '--no-heading',
--     '--with-filename', '--line-number', '--column', '--smart-case', '-.' } }
--   end, { desc = 'Search Ripgrep' })
--

--     f = {
--         name = "Find",
--         f = {
--             -- "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false, hidden = true})<cr>",
--             "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false, find_command = {'rg', '--files', '--hidden', '-g', '!.git'}})<cr>",
--             "Find files (relative cwd)",
--         },
--         ["."] = {
--             -- TODO: Need to understand how to use the 'utils.buffer.dir()'
--             -- command to get this to work
--             "<cmd>lua require('telescope.builtin').find_files({find_command = {'rg', '--files', '--hidden', '-g', '!.git'}, cwd='utils.buffer.dir()'})<cr>", "Find files (relative open buffer)",
--         },
--     ["F"] = { "<cmd>Telescope live_grep theme=ivy<cr>", "Find Text" },
