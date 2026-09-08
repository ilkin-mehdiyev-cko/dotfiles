-- JS/TS tooling: Biome for formatting (replaces Prettier), oxlint for linting (replaces ESLint).
-- Binaries installed globally via npm: `oxlint`, `@biomejs/biome`.
return {
  -- Biome as the formatter for JS/TS/JSON
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "biome" },
        javascriptreact = { "biome" },
        typescript = { "biome" },
        typescriptreact = { "biome" },
        json = { "biome" },
        jsonc = { "biome" },
      },
    },
  },

  -- oxlint as the linter, via its built-in language server (`oxlint --lsp`)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {},
      },
    },
  },
}
