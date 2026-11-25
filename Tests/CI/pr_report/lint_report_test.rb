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

    def test_summary_with_both_details
        unique = "# RuboCop Inspection Report\n\n1 offense\n\n### a.rb - (1 offenses)\n- x\n"
        critical = "# RuboCop Inspection Report\n\nNo offenses\n"

        result = L.summary(full_lines: 250, counts: "5  Layout/X\n", unique: unique, critical: critical)

        intro, rest = result.split("\n\n", 2)
        assert_includes intro, "250 lines"
        assert_includes intro, "200-line limit"
        assert_includes intro, "summary"
        assert_includes intro, "The full report is in this run's job summary."
        assert_equal "```text\n5  Layout/X\n```\n\n" \
                     "#### Cops with one offense\n\n### a.rb - (1 offenses)\n- x\n\n" \
                     "#### Warnings and worse\n\nNone.\n", rest
    end

    def test_summary_drops_the_blank_lines_rubocop_starts_counts_with
        result = L.summary(full_lines: 250, counts: "\n5  Layout/X\n", unique: nil, critical: "")

        assert_includes result, "```text\n5  Layout/X\n```\n"
    end

    def test_summary_without_unique_omits_that_heading
        critical = "title\n\ncount\n\n### b.rb - (2 offenses)\n- y\n"

        result = L.summary(full_lines: 201, counts: "2  A/B\n", unique: nil, critical: critical)

        refute_includes result, "Cops with one offense"
        assert result.end_with?("```\n\n#### Warnings and worse\n\n### b.rb - (2 offenses)\n- y\n")
    end

    def test_summary_detail_of_exactly_200_lines_is_not_cut
        critical = "t\n\n### f\n#{"- x\n" * 197}"

        result = L.summary(full_lines: 300, counts: "1  A/B\n", unique: nil, critical: critical)

        assert result.end_with?("#### Warnings and worse\n\n### f\n#{"- x\n" * 197}")
        refute_includes result, "Cut at"
    end

    def test_summary_detail_over_200_lines_is_cut_with_a_note
        critical = "t\n\n### f\n#{"- x\n" * 198}"

        result = L.summary(full_lines: 300, counts: "1  A/B\n", unique: nil, critical: critical)

        kept = "#### Warnings and worse\n\n### f\n#{"- x\n" * 197}"
        assert result.end_with?("#{kept}\n_Cut at 200 lines. The full report is in this run's job summary._\n")
    end
end
