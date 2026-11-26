-- Keep markdown fully rendered in Normal mode (raw text still shows in Insert mode).
-- Prevents line heights changing under the cursor, which caused jumping with scrolloff = 999.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    anti_conceal = { enabled = false },
    -- Table row wrapping can assert ("table unit exceeds column width") on wide chars
    -- such as emoji/icons in narrow windows. Disable it; long rows fall back to normal 'wrap'.
    pipe_table = { wrap = false },
  },
}
