-- friendly-snippets ships some collections under pseudo-language names that are
-- not real Neovim filetypes, so LuaSnip's from_vscode loader never activates them.
-- Per the friendly-snippets README, they must be mapped in with filetype_extend():
-- https://github.com/rafamadriz/friendly-snippets#add-snippets-from-a-framework-to-a-filetype
return {
  {
    "L3MON4D3/LuaSnip",
    init = function()
      -- :Snippets — fuzzy-browse all snippets for the current buffer (trigger,
      -- source filetype, name) with body preview; <cr> inserts the trigger.
      vim.api.nvim_create_user_command("Snippets", function()
        local ls = require("luasnip")
        local entries, by_entry = {}, {}
        for _, ft in ipairs(ls.get_snippet_filetypes()) do
          for _, snip in ipairs(ls.get_snippets(ft)) do
            if not snip.hidden then
              local entry = string.format("%-24s %-14s %s", snip.trigger, "[" .. ft .. "]", snip.name or "")
              if not by_entry[entry] then
                by_entry[entry] = snip
                entries[#entries + 1] = entry
              end
            end
          end
        end
        require("fzf-lua").fzf_exec(entries, {
          prompt = "Snippets❯ ",
          preview = function(items)
            local snip = by_entry[items[1]]
            if not snip then
              return ""
            end
            local ok, docstring = pcall(function()
              local doc = snip:get_docstring()
              return type(doc) == "table" and table.concat(doc, "\n") or tostring(doc)
            end)
            return ok and docstring or (snip.name or "")
          end,
          actions = {
            ["default"] = function(selected)
              local snip = by_entry[selected[1]]
              if snip then
                vim.api.nvim_put({ snip.trigger }, "c", true, true)
              end
            end,
          },
        })
      end, { desc = "Browse snippets for current buffer" })
    end,
    opts = function()
      local extends = {
        -- standardized doc-comment collections
        c = { "cdoc" },
        cpp = { "cppdoc" },
        cs = { "csharpdoc" },
        java = { "javadoc", "java-testing" },
        javascript = { "jsdoc" },
        javascriptreact = { "jsdoc" },
        kotlin = { "kdoc" },
        lua = { "luadoc" },
        php = { "phpdoc" },
        python = { "pydoc" },
        ruby = { "rdoc" },
        rust = { "rustdoc" },
        sh = { "shelldoc" },
        zsh = { "shelldoc" },
        typescript = { "tsdoc" },
        typescriptreact = { "tsdoc" },
        -- framework collections are opt-in by design; extend what you use, e.g.:
        -- ruby = { "rdoc", "rails", "rspec" },
        -- python = { "pydoc", "django", "django-rest" },
        -- dart = { "flutter" },
      }
      for ft, exts in pairs(extends) do
        require("luasnip").filetype_extend(ft, exts)
      end
      -- license/loremipsum snippets in every buffer (noisy; enable if wanted):
      -- require("luasnip").filetype_extend("all", { "license", "loremipsum" })
    end,
  },
}
