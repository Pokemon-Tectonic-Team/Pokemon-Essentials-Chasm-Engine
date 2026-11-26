require "simplecov/cli"

module PrReport
    # Makes `simplecov patch` diff with `--ignore-all-space`, so a line whose only change is
    # whitespace, such as code re-indented by a lint pass, doesn't count as changed. SimpleCov
    # 1.3.2 builds that diff's arguments inside ChangedLines#git_diff, so this adds the option to
    # the one git call carrying `--unified=0`, which only that diff passes.
    module SimplecovIgnoreWhitespace
        def capture(*argv)
            diff = argv.index("diff")
            return super unless diff && argv.include?("--unified=0")

            super(*argv.dup.insert(diff + 1, "--ignore-all-space"))
        end
    end
end

SimpleCov::CLI::Git.singleton_class.prepend(PrReport::SimplecovIgnoreWhitespace)
