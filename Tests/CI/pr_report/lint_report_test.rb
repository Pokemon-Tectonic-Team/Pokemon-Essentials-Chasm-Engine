require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/lint_report"

class LintReportTest < Minitest::Test
    L = PrReport::LintReport

    def test_summarise_only_above_200_lines
        refute L.summarise?("x\n" * 200)
        assert L.summarise?("x\n" * 201)
    end

    def test_full_section_removes_the_title_at_the_start
        assert_equal "body\n", L.full_section("# RuboCop Inspection Report\n\nbody\n")
    end

    def test_full_section_leaves_a_title_elsewhere
        text = "x\n# RuboCop Inspection Report\n\nbody\n"
        assert_equal text, L.full_section(text)
    end

    def test_none_changed
        assert_equal "No Ruby files changed.\n", L.none_changed
    end

    def test_error
        assert_equal "RuboCop couldn't run:\n\n```text\nboom\n```\n", L.error("boom\n")
    end

    def test_headline_is_the_first_line_without_its_newline
        assert_equal "boom", L.headline("boom\ntrace\n")
        assert_equal "", L.headline("")
    end

    def test_error_shows_only_the_first_line
        assert_equal "RuboCop couldn't run:\n\n```text\nboom\n```\n", L.error("boom\ntrace 1\ntrace 2\n")
    end

    def test_summary_with_unique_shows_counts_then_offenses_from_the_first_file_heading
        unique = "# RuboCop Inspection Report\n\n1 offense\n\n### a.rb - (1 offenses)\n- x\n"

        result = L.summary(counts: "5  Layout/X\n", safe: 0, unique: unique)

        assert_equal "```text\n5  Layout/X\n```\n\n### a.rb - (1 offenses)\n- x\n", result
    end

    def test_summary_shows_plain_counts
        counts = "\n5  Layout/X [Safe Correctable]\n1  A/B [Unsafe Correctable]\n--\n6  Total in 1 files\n"

        result = L.summary(counts: counts, safe: 0, unique: nil)

        assert_equal "```text\n5  Layout/X\n1  A/B\n--\n6  Total in 1 files\n```\n", result
    end

    def test_summary_names_the_safe_correctable_offenses_only_when_there_are_some
        with = L.summary(counts: "5  Layout/X\n", safe: 5, unique: nil)
        without = L.summary(counts: "5  Layout/X\n", safe: 0, unique: nil)

        assert_equal "```text\n5  Layout/X\n```\n\n...and 5 safely auto-correctable offenses.\n", with
        refute_includes without, "auto-correctable"
    end

    def test_summary_without_unique_is_just_the_counts_block
        assert_equal "```text\n2  A/B\n```\n", L.summary(counts: "2  A/B\n", safe: 0, unique: nil)
    end

    def test_summary_puts_the_safe_line_between_the_counts_and_the_offenses
        result = L.summary(counts: "1  A/B\n", safe: 3, unique: "### f\n- x\n")

        assert_equal "```text\n1  A/B\n```\n\n...and 3 safely auto-correctable offenses.\n\n### f\n- x\n", result
    end

    def test_summary_says_none_when_unique_has_no_file_heading
        unique = "# RuboCop Inspection Report\n\n1 file inspected, no offenses detected:\n\n"

        result = L.summary(counts: "1  A/B\n", safe: 0, unique: unique)

        assert result.end_with?("```\n\nNone.\n")
    end

    def test_summary_offenses_of_exactly_200_lines_are_not_cut
        unique = "### f\n#{"- x\n" * 199}"

        result = L.summary(counts: "1  A/B\n", safe: 0, unique: unique)

        assert result.end_with?("\n#{unique}")
        refute_includes result, "Cut at"
    end

    def test_summary_offenses_over_200_lines_are_cut_with_a_note
        unique = "### f\n#{"- x\n" * 200}"

        result = L.summary(counts: "1  A/B\n", safe: 0, unique: unique)

        kept = "### f\n#{"- x\n" * 199}"
        assert result.end_with?("\n#{kept}\n#{L::CUT_NOTE}\n")
    end

    def test_summary_cut_closes_an_open_code_fence
        unique = "### f\n```\n#{"x\n" * 250}```\n"

        result = L.summary(counts: "1  A/B\n", safe: 0, unique: unique)

        assert result.end_with?("x\n```\n\n#{L::CUT_NOTE}\n")
    end
end
