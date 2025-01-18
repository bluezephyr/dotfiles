-- Codeium plugin that uses nvim-cmp
-- https://github.com/Exafunction/codeium.nvim
-- Note that the plugin must be registered in nvim-cmp
-- The offical plugin (not using nvmim-cmp) is here: https://github.com/Exafunction/codeium.vim
return {
    "Exafunction/codeium.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("codeium").setup({
        })
    end
}
