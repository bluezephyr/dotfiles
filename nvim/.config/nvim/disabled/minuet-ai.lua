return {
  {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local gemini_key = os.getenv('GEMINI_API_KEY')

      if not gemini_key or gemini_key == '' then
        vim.notify('[Minuet] GEMINI_API_KEY is not set. Plugin will not be loaded.', vim.log.levels.ERROR)
        return
      end

      require('minuet').setup {
        -- Timeout in seconds
        request_timeout = 20,

        virtualtext = {
          auto_trigger_ft = { "*" },
          auto_trigger_ignore_ft = {},
          keymap = {
            accept = '<C-y>',
            accept_line = '<C-l>',
            accept_n_lines = '<C-h>',
            prev = '<C-k>',
            next = '<C-j>',
            dismiss = '<C-e>',
          },
        },

        cmp = { enable_auto_complete = false },
        blink = { enable_auto_complete = false },

        provider = 'gemini',
        provider_options = {
          gemini = {
            model = 'gemini-2.0-flash-lite',
            optional = {
              generationConfig = {
                maxOutputTokens = 256,
                thinkingConfig = { thinkingBudget = 0, },
              },
              safetySettings = { {
                category = 'HARM_CATEGORY_DANGEROUS_CONTENT',
                threshold = 'BLOCK_ONLY_HIGH',
              } },
            },
          },
        },
      }

      vim.notify('[Minuet] Plugin loaded successfully with Gemini provider.', vim.log.levels.INFO)
    end,
  },
}
