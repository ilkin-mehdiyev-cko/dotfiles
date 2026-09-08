-- oil.nvim — edit your filesystem like a normal buffer.
-- Complements neo-tree (tree view) with a buffer-style file editor.
return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { { "nvim-mini/mini.icons", opts = {} } },
    -- Lazy loading is not recommended by the author; load on startup.
    lazy = false,
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
  },
}
