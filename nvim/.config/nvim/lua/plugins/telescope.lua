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

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'

      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
      vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>ft', builtin.builtin, { desc = '[F]ind [T]elescope' })
      vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader>f*', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = '[F]ind [C]ommands' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>fo', builtin.vim_options, { desc = '[F]ind Vim [O]ptions' })
      vim.keymap.set('n', '<leader>h', builtin.oldfiles, { desc = 'Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<c-p>', function()
        require('telescope.builtin').find_files { find_command = { 'fd', '--hidden', '--no-ignore-vcs' } }
      end, { desc = 'Find All Files' })

      vim.keymap.set('n', '<leader>f.', function()
        require('telescope.builtin').find_files { cwd = vim.fn.expand('%:p:h'), find_command = { 'fd' } }
      end, { desc = '[F]ind [F]iles Relative Current' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>fn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[F]ind [N]eovim files' })

      vim.keymap.set('n', '<leader>fm', function()
        require('telescope.builtin').man_pages { sections = { 'ALL' } }
      end, { desc = '[F]ind [M]an Pages' })

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

      vim.keymap.set('n', '<leader>/', require('telescope.builtin').current_buffer_fuzzy_find,
        { desc = 'Fuzzy search in current buffer' })

      -- TODO: Remap - duplicate
      vim.keymap.set('n', '<leader>fs', function()
        require('telescope.builtin').live_grep { vimgrep_arguments = { 'rg', '--color=never', '--no-heading',
          '--with-filename', '--line-number', '--column', '--smart-case', '-.', '--no-ignore', '--glob=!.git/*' } }
      end, { desc = '[F]ind text (all)' })

      -- Git commands
      vim.keymap.set('n', '<leader>gs', require('telescope.builtin').git_status, { desc = 'Git Status' })

      -- load refactoring Telescope extension
      require("telescope").load_extension("refactoring")

      vim.keymap.set(
        { "n", "x" },
        "<leader>r",
        function() require('telescope').extensions.refactoring.refactors() end, { desc = 'Refactor' }
      )
      vim.keymap.set('n', '<leader>gc', require('telescope.builtin').git_commits, { desc = 'Git Commits' })
    end
  },
}
