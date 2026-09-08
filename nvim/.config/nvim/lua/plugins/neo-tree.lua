-- https://github.com/nvim-neo-tree/neo-tree.nvim
-- Only the settings that differ from neo-tree's defaults. Nested tables are
-- deep-merged, so the default mappings survive alongside the ones named here.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      close_if_last_window = false,
      enable_diagnostics = false,
      sort_case_insensitive = false,
      -- A list, so it replaces the default instead of merging into it.
      open_files_do_not_replace_types = { "terminal", "trouble", "qf" },

      default_component_configs = {
        icon = {
          folder_closed = " ",
          folder_open = " ",
          folder_empty = " ",
        },
        modified = {
          symbol = "[+]",
        },
        name = {
          trailing_slash = false,
        },
        git_status = {
          symbols = {
            added     = "",
            modified  = "",
            deleted   = "✖ ",
            renamed   = " ",
            untracked = " ",
            ignored   = " ",
            unstaged  = "✗ ",
            staged    = " ",
            conflict  = " ",
          },
        },
      },

      window = {
        position = "current",
        mappings = {
          -- nowait off: <space> is the leader too.
          ["<space>"] = { "toggle_node", nowait = false },
          ["<esc>"] = "revert_preview",
          -- Matches the global default, but source windows inherit this table,
          -- so it also overrides the buffers source's own "buffer_delete".
          ["d"] = "delete",
          ["h"] = "close_node",
          ["l"] = "open",
        },
      },

      filesystem = {
        filtered_items = {
          visible = false,
          -- Empty on purpose: it replaces the default { ".DS_Store", "thumbs.db" }.
          hide_by_name = {},
        },
        follow_current_file = { enabled = true, leave_dirs_open = false },
        group_empty_dirs = false,
        use_libuv_file_watcher = false,
        window = {
          mappings = {
            ["<c-x>"] = "clear_filter",
          },
        },
      },

      buffers = {
        follow_current_file = { leave_dirs_open = false },
        show_unloaded = true,
      },

      git_status = {
        window = {
          position = "float",
        },
      },
    })

    vim.cmd([[nnoremap \ :Neotree toggle current reveal_force_cwd<cr>]])
  end
}
