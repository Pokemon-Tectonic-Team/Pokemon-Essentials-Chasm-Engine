require "simplecov/cli"

module PrReport
    # Git ends a diff's `+++` header with a tab when the path contains a space. SimpleCov 1.3.2's
    # ChangedLines#diff_path keeps that tab, so the path matches no coverage key and `simplecov
    # patch` silently skips the file. Remove this once SimpleCov strips the tab itself.
    module SimplecovDiffPath
        def diff_path(line)
            super(line.chomp.delete_suffix("\t"))
        end
    end
end

SimpleCov::CLI::Patch::ChangedLines.prepend(PrReport::SimplecovDiffPath)
