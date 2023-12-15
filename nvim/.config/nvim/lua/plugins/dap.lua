-- See https://github.com/mfussenegger/nvim-dap
-- and https://github.com/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)
-- See `:help dap.txt`, `:help dap-adapter.txt`, `:help dap-configuration.txt`
--
-- For inspiration, see https://github.com/Civitasv/runvim/blob/master/lua/plugins/daps/init.lua
return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
    },

    config = function()
        local dap = require('dap')

        dap.adapters.cppdbg = {
            id = 'cppdbg',
            type = 'executable',
            command = '/home/jens/repos/vscode/linux/extension/debugAdapters/bin/OpenDebugAD7',
        }

        vim.keymap.set('n', '<F5>', "<cmd>lua require('dap').continue()<cr>", { desc = 'Debug: run' })
        vim.keymap.set('n', '<F10>', "<cmd>lua require('dap').step_over()<cr>", { desc = 'Debug: step over' })
        vim.keymap.set('n', '<F11>', "<cmd>lua require('dap').step_into()<cr>", { desc = 'Debug: step into' })
        vim.keymap.set('n', '<F12>', "<cmd>lua require('dap').step_out()<cr>", { desc = 'Debug: out' })
        vim.keymap.set('n', '<Leader>b', "<cmd>lua require('dap').toggle_breakpoint()<cr>",
            { desc = 'Debug: toggle breakpoint' })
    end
}
