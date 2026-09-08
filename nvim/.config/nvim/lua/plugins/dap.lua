return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dapui = require('dapui')
      local dap = require("dap")
      local mason_nvim_dap = require("mason-nvim-dap")
      local keymap = vim.keymap.set

      -- require("nvim-dap-virtual-text").setup({})

      ---- DAP ui ----
      dapui.setup({
        mappings = {
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              "watches",
              "breakpoints",
              "stacks",
            },
            size = 40,
            position = "right",
          },
          {
            elements = {
              "repl",
              "console",
            },
            size = 0.25,
            position = "bottom",
          },
        },
      })

      ---- DAP ----
      dap.listeners.before.launch.dapui = function()
        dapui.open()
      end

      -- Wrap dap.run to intercept Python launch requests and set the 'cwd' to Neovim's
      -- current directory if it's missing from the configuration.
      local original_run = dap.run
      dap.run = function(config, ...)
        if config.type == 'python' and config.request == 'launch' then
          if config.cwd == nil then
            config.cwd = vim.fn.getcwd()

            require("snacks").notify("CWD was not set, defaulting to " .. config.cwd, {
              title = "DAP CWD Fix",
              level = vim.log.levels.INFO,
            })
          end
        end
        return original_run(config, ...)
      end

      ---- Icons ----
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = ">", texthl = "", linehl = "", numhl = "" })

      ---- Keymaps ----
      keymap('n', '<F5>', function() dap.continue() end, { desc = "DAP: continue" })
      keymap('n', '<F10>', function() dap.step_over() end, { desc = "DAP: step over" })
      keymap('n', '<F11>', function() dap.step_into() end, { desc = "DAP: step into" })
      keymap('n', '<F8>', function() dap.step_out() end, { desc = "DAP: step out" })
      keymap('n', '<F9>', function() dap.toggle_breakpoint() end, { desc = "DAP: toggle breakpoint" })
      keymap('n', '<F4>', function() dap.terminate({ on_done = dapui.close }) end, { desc = "DAP: terminate" })
      keymap('n', '<F6>', function() dap.run_to_cursor() end, { desc = "DAP: run to cursor" })
      keymap('n', '<Leader>dr', function() dap.run_to_cursor() end, { desc = "DAP: run to cursor" })
      keymap('n', '<Leader>dR', function() dap.restart() end, { desc = "DAP: restart" })
      keymap('n', '<Leader>dj', function() dap.down() end, { desc = "DAP: callstack down" })
      keymap('n', '<Leader>dk', function() dap.up() end, { desc = "DAP: callstack up" })
      keymap('n', '<Leader>do', function() dapui.open() end, { desc = "DAP: open UI" })
      keymap('n', '<Leader>dc', function() dapui.close() end, { desc = "DAP: close UI" })

      -- Keymap: Print variable under cursor in hex using gdb
      keymap('n', '<leader>dx', function()
        local var = vim.fn.expand("<cword>")
        dapui.eval(string.format("-exec print/x %s", var))
      end, { desc = "Print variable in hex" })

      keymap('n', '<leader>da', function()
        local var = vim.fn.expand("<cword>")
        dapui.eval(string.format("-exec print/x *%s@10", var))
      end, { desc = "Print array in hex" })

      keymap({ 'n', 'v' }, '<M-e>', function()
        dapui.eval()
      end, { desc = "Show variable value" })

      ---- DAP language adapters ----
      -- Make sure to use the nvim_dap adapter name (see
      -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua)
      local adapters = {
        'python',
        'cppdbg',
        'codelldb',
      }

      -- Empty, but present: without a handlers table no adapter is set up at
      -- all, and an empty one sends every adapter through default_setup.
      mason_nvim_dap.setup({
        ensure_installed = adapters,
        handlers = {},
      })

      -- Add the native GDB adapter - requires gdb 14 or greater
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
      }
    end
  }
}
