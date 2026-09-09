-- Colour helpers for the configs that derive their highlights from the theme,
-- so a colorscheme switch keeps the intent instead of the previous colours.
local M = {}

-- A highlight group's attributes, resolved through its links.
function M.hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

-- Mixes two colours, `amount` of the way from the first toward the second.
function M.blend(from, to, amount)
  local out = 0
  for _, shift in ipairs({ 65536, 256, 1 }) do
    local a, b = math.floor(from / shift) % 256, math.floor(to / shift) % 256
    out = out + math.floor(a + (b - a) * amount + 0.5) * shift
  end
  return out
end

return M
