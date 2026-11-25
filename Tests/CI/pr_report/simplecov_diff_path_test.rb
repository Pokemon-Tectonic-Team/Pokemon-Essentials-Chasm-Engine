require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/simplecov_diff_path"

class SimplecovDiffPathTest < Minitest::Test
    def diff_path(line)
        SimpleCov::CLI::Patch::ChangedLines.diff_path(line)
    end

    def test_is_prepended_onto_changed_lines
        assert_includes SimpleCov::CLI::Patch::ChangedLines.singleton_class.ancestors, PrReport::SimplecovDiffPath
    end

    def test_drops_the_tab_git_adds_after_a_path_with_a_space
        assert_equal "Plugins/Chasm Battle/a.rb", diff_path("+++ b/Plugins/Chasm Battle/a.rb\t\n")
    end

    def test_plain_header
        assert_equal "lib/a.rb", diff_path("+++ b/lib/a.rb\n")
    end

    def test_quoted_header
        assert_equal "lib/we\"ird.rb", diff_path("+++ \"b/lib/we\\\"ird.rb\"\n")
    end

    def test_dev_null_is_nil
        assert_nil diff_path("+++ /dev/null\n")
    end
end
