-- Add indentation guides even on blank lines
-- https://github.com/lukas-reineke/indent-blankline.nvim/
-- See `:help indent_blankline.txt`
return {
    {
        'lukas-reineke/indent-blankline.nvim',
        opts = {
            char = '┊',
            show_trailing_blankline_indent = false,
        },
    },
}
