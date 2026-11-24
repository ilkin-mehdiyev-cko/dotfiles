-- Java (jdtls) fix: LazyVim's java extra globs *every* jar in $MASON/share/java-test/
-- and passes them to jdtls as OSGi extension bundles. Two of them are NOT bundles
-- (no bundle manifest), so jdtls logs "Failed to load extension bundles":
--   * com.microsoft.java.test.runner-jar-with-dependencies.jar  (run as a process, not a bundle)
--   * jacocoagent.jar                                           (coverage agent, not a bundle)
-- `opts.jdtls` is applied as a function over the final jdtls config, so we filter them out here.
return {
  -- Format Java with google-java-format (2-space indent, 100 columns, matches the
  -- repos' .editorconfig) instead of jdtls's built-in Eclipse formatter.
  { "mason-org/mason.nvim", opts = { ensure_installed = { "google-java-format" } } },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { java = { "google-java-format" } } },
  },

  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- Loose .java files (no gradlew/pom.xml/.git above them) have no project root.
      -- nvim-jdtls then falls back to the cwd, so opening ~/workspace/Foo.java made
      -- jdtls import every Gradle/Maven project under ~/workspace. Give such files
      -- an empty root instead, so there is nothing to import.
      opts.root_dir = function(path)
        local root = vim.fs.root(path, vim.lsp.config.jdtls.root_markers)
        if root then
          return root
        end
        local standalone = vim.fn.stdpath("cache") .. "/jdtls-standalone"
        vim.fn.mkdir(standalone, "p")
        return standalone
      end

      -- jdtls >= 1.63 needs Java 25 to run itself (it exits with code 13 on 21).
      -- Run the server on the sdkman JDK 25; projects keep building with their own JDK.
      local jdk25 = vim.fn.glob("~/.sdkman/candidates/java/25*-tem/bin/java", false, true)[1]
      if jdk25 then
        table.insert(opts.cmd, "--java-executable=" .. jdk25)
      end

      opts.jdtls = function(config)
        local bundles = config.init_options and config.init_options.bundles
        if bundles then
          config.init_options.bundles = vim.tbl_filter(function(jar)
            return not jar:find("runner%-jar%-with%-dependencies%.jar$")
              and not jar:find("jacocoagent%.jar$")
              -- jdtls already ships these; installing them again fails with
              -- "A bundle is already installed with the name org.objectweb.asm..."
              and not jar:find("org%.objectweb%.asm")
          end, bundles)
        end
        return config
      end
    end,
  },
}
