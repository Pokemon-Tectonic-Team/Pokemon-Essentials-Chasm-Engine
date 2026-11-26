require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/comment_body"

class CommentBodyTest < Minitest::Test
    C = PrReport::CommentBody
    URL = "https://example.test/run/1".freeze

    def test_build_lays_out_every_section
        result = C.build(syntax: "success", tests: "success", run_url: URL,
                         patch: { text: "ok\n", exit: 0 }, totals: { "line" => 12.346, "branch" => 5.6 },
                         lint: "Lint text")

        assert_equal "## Tests report\n\n" \
                     "Syntax check and tests passed. [Run details](#{URL})\n\n" \
                     "### Coverage of changed lines\n\n" \
                     "```text\nok\n```\n\n" \
                     "Whole codebase, for reference: line 12.35%, branch 5.60%.\n\n" \
                     "### Lint\n\n" \
                     "Lint text\n", result
    end

    def test_build_cuts_to_the_comment_limit_with_a_note
        result = C.build(syntax: "success", tests: "success", run_url: URL,
                         patch: { text: "ok\n", exit: 0 }, totals: nil, lint: "line\n" * 20_000)

        assert_operator result.length, :<=, 60_000
        assert result.end_with?("\n")
        note = result.lines.last
        assert_includes note, "GitHub's comment limit"
        assert_includes note, "[the run](#{URL})"
        assert result.start_with?("## Tests report\n\n")
    end

    def test_status_passed
        assert_equal "Syntax check and tests passed.", C.status(syntax: "success", tests: "success")
    end

    def test_status_names_each_failed_step
        assert_equal "Syntax check: failure, tests: skipped. The coverage figures may come from a partial run.",
                     C.status(syntax: "failure", tests: "skipped")
    end

    def test_status_with_only_tests_not_successful
        assert_equal "Tests: cancelled. The coverage figures may come from a partial run.",
                     C.status(syntax: "success", tests: "cancelled")
    end

    def test_patch_section_with_exit_zero_is_the_block
        assert_equal "```text\na\n```\n", C.patch_section({ text: "a\n", exit: 0 })
    end

    def test_patch_section_with_other_exit_says_so
        assert_equal "`simplecov patch` exited 2:\n\n```text\na\n```\n", C.patch_section({ text: "a\n", exit: 2 })
    end

    def test_totals_line_with_both
        assert_equal "line 12.35%, branch 5.60%", C.totals_line({ "line" => 12.346, "branch" => 5.6 })
    end

    def test_totals_line_with_one
        assert_equal "line 0.00%", C.totals_line({ "line" => 0.0 })
        assert_equal "branch 5.60%", C.totals_line({ "branch" => 5.6 })
    end

    def test_totals_line_unavailable
        assert_equal "unavailable", C.totals_line(nil)
        assert_equal "unavailable", C.totals_line({})
    end
end
