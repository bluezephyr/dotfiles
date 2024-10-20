return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "jay-babu/mason-nvim-dap.nvim",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            local dapui = require('dapui')
            local dap = require("dap")
            local mason_nvim_dap = require("mason-nvim-dap")
            local keymap = vim.keymap.set
            local opts = { noremap = true, silent = true }

            require("nvim-dap-virtual-text").setup({})

            ---- DAP ui ----
            dapui.setup({
                icons = { expanded = "▾", collapsed = "▸" },
                mappings = {
                    expand = { "<CR>", "<2-LeftMouse>" },
                    open = "o",
                    remove = "d",
                    edit = "e",
                    repl = "r",
                    toggle = "t",
                },
                expand_lines = true,
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
                floating = {
                    max_height = nil,
                    max_width = nil,
                    border = "single",
                    mappings = {
                        close = { "q", "<Esc>" },
                    },
                },
                windows = { indent = 2 },
                render = {
                    indent = 1,
                    max_type_length = nil,
                },
            })

            ---- DAP ----
            dap.set_log_level("TRACE")
            dap.listeners.before.launch.dapui = function()
                dapui.open()
            end

            ---- Icons ----
            vim.fn.sign_define("DapBreakpoint", { text = "*", texthl = "", linehl = "", numhl = "" })
            vim.fn.sign_define("DapStopped", { text = "!", texthl = "", linehl = "", numhl = "" })

            ---- Keymaps ----
            keymap('n', '<F5>', function() dap.continue() end, { desc = "continue" })
            keymap('n', '<F10>', function() dap.step_over() end, { desc = "step over" })
            keymap('n', '<F11>', function() dap.step_into() end, { desc = "step into" })
            keymap('n', '<F22>', function() dap.step_out() end, { desc = "step out" }) -- Shift-f10 -> f22
            keymap('n', '<F9>', function() dap.toggle_breakpoint() end, { desc = "toggle breakpoint" })
            keymap("n", '<F4>', function() dap.terminate({ cb = dapui.close() }) end, { desc = "terminate" })
            keymap('n', '<Leader>dr', function() dap.run_to_cursor() end, { desc = "run to cursor" })
            keymap('n', '<Leader>dR', function() dap.restart() end, { desc = "restart" })
            keymap("n", '<Leader>dw', function() dapui.elements.watches.add(vim.fn.expand("<cword>")) end,
                { desc = "add watch" })
            -- keymap("n", "<Leader>dw", "<CMD>lua require('dapui').float_element('watches', { enter = true })<CR>", opts)
            -- keymap("n", "<Leader>ds", "<CMD>lua require('dapui').float_element('scopes', { enter = true })<CR>", opts)
            -- keymap("n", "<Leader>dr", "<CMD>lua require('dapui').float_element('repl', { enter = true })<CR>", opts)

            ---- DAP language adapters ----
            require("mason").setup()

            -- Make sure to use the nvim_dap adapter name (see
            -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua)
            local adapters = {
                'python',
                'cppdbg',
            }

            mason_nvim_dap.setup({
                ensure_installed = adapters,
                automatic_installation = false,
                handlers = {
                    function(config)
                        -- all sources with no handler get passed here
                        -- Keep original functionality
                        mason_nvim_dap.default_setup(config)
                    end,
                },
            })
        end
    }
}
