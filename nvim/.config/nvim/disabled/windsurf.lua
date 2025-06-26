-- Windsurf (formerly Codeium) plugin that uses nvim-cmp
-- https://github.com/Exafunction/windsurf.nvim
-- Note that the plugin must be registered in nvim-cmp
return {
    "Exafunction/windsurf.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("codeium").setup({ })
    end
}
