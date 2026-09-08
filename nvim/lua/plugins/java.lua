-- Java (jdtls) fix: LazyVim's java extra globs *every* jar in $MASON/share/java-test/
-- and passes them to jdtls as OSGi extension bundles. Two of them are NOT bundles
-- (no bundle manifest), so jdtls logs "Failed to load extension bundles":
--   * com.microsoft.java.test.runner-jar-with-dependencies.jar  (run as a process, not a bundle)
--   * jacocoagent.jar                                           (coverage agent, not a bundle)
-- `opts.jdtls` is applied as a function over the final jdtls config, so we filter them out here.
return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.jdtls = function(config)
        local bundles = config.init_options and config.init_options.bundles
        if bundles then
          config.init_options.bundles = vim.tbl_filter(function(jar)
            return not jar:find("runner%-jar%-with%-dependencies%.jar$")
              and not jar:find("jacocoagent%.jar$")
          end, bundles)
        end
        return config
      end
    end,
  },
}
