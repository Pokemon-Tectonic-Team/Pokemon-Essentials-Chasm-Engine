require "open3"
require "stringio"
require "tmpdir"
require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/simplecov_ignore_whitespace"

class SimplecovIgnoreWhitespaceTest < Minitest::Test
    def git(dir, *args)
        _out, err, status = Open3.capture3("git", "-C", dir, "-c", "user.name=Test", "-c", "user.email=test@example.com",
            "-c", "core.autocrlf=false", *args)
        raise err unless status.success?
    end

    # The lines `simplecov patch` scores in a repository whose one commit holds before, with after
    # in the working tree.
    def changedLines(before, after)
        Dir.mktmpdir do |dir|
            git(dir, "init", "-q")
            File.write(File.join(dir, "a.rb"), before)
            git(dir, "add", "a.rb")
            git(dir, "commit", "-q", "-m", "base")
            File.write(File.join(dir, "a.rb"), after)
            Dir.chdir(dir) do
                result = SimpleCov::CLI::Patch::ChangedLines.call("HEAD", find_renames: false, stderr: StringIO.new)
                return result.fetch(:changes)
            end
        end
    end

    def test_is_prepended_onto_git
        assert_includes SimpleCov::CLI::Git.singleton_class.ancestors, PrReport::SimplecovIgnoreWhitespace
    end

    def test_a_reindented_line_is_not_changed
        assert_empty changedLines("if a\n  b\nend\n", "if a\n    b\nend\n")
    end

    def test_whitespace_added_inside_a_line_is_not_changed
        assert_empty changedLines("x = a+b\n", "x = a + b\n")
    end

    def test_a_line_with_other_changes_still_counts
        assert_equal({ "a.rb" => [2] }, changedLines("if a\n  b\nend\n", "if a\n    c\nend\n"))
    end

    def test_lines_keep_their_numbers_beside_reindented_ones
        assert_equal({ "a.rb" => [3] }, changedLines("  a\n  b\n  c\n", "    a\n    b\n    d\n"))
    end
end
