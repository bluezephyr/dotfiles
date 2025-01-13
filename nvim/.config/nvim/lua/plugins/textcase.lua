return {
    "johmsalas/text-case.nvim",
    event = "VeryLazy",
    config = function()
        require("textcase").setup({
            default_keymappings_enabled = false,
            prefix = "ga",
            substitude_command_name = nil,
            enabled_methods = {
                -- "to_upper_case",
                -- "to_lower_case",
                "to_snake_case",
                -- "to_dash_case",
                -- "to_title_dash_case",
                -- "to_constant_case",
                -- "to_dot_case",
                -- "to_comma_case",
                -- "to_phrase_case",
                "to_camel_case",
                "to_pascal_case",
                -- "to_title_case",
                -- "to_path_case",
                -- "to_upper_phrase_case",
                -- "to_lower_phrase_case",
            },
        })
    end,
    keys = {
        { "gas",  function() require("textcase").lsp_rename('to_snake_case') end,     mode = { "n" },  desc = "To snake_case" },
        { "gac",  function() require("textcase").lsp_rename('to_camel_case') end,     mode = { "n" },  desc = "To camelCase" },
        { "gap",  function() require("textcase").lsp_rename('to_pascal_case') end,    mode = { "n" },  desc = "To PascalCase" },
        { "gaws", function() require("textcase").current_word('to_snake_case') end,   mode = { "n" },  desc = "To snake_case" },
        { "gawc", function() require("textcase").current_word('to_camel_case') end,   mode = { "n" },  desc = "To camelCase"  },
        { "gawp", function() require("textcase").current_word('to_pascal_case') end,  mode = { "n" },  desc = "To PascalCase" },
    }
}
