require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/offense_counts"

class OffenseCountsTest < Minitest::Test
    def test_parse_reads_rows_in_order_and_skips_blank_separator_and_total
        text = "\n86   Layout/SpaceAfterComma [Safe Correctable]\n" \
               "2    Lint/AmbiguousRange [Unsafe Correctable]\n" \
               "1    Layout/EndOfLine\n--\n216  Total in 1 files\n"

        expected = [
            { count: 86, cop: "Layout/SpaceAfterComma", correctable: :safe },
            { count: 2, cop: "Lint/AmbiguousRange", correctable: :unsafe },
            { count: 1, cop: "Layout/EndOfLine", correctable: nil }
        ]
        assert_equal expected, PrReport::OffenseCounts.parse(text)
    end

    def test_parse_of_empty_text_is_empty
        assert_equal [], PrReport::OffenseCounts.parse("\n")
    end

    def test_parse_raises_naming_an_unreadable_line
        error = assert_raises(PrReport::Error) { PrReport::OffenseCounts.parse("1  A/B\nnot a row\n") }
        assert_includes error.message, "not a row"
    end

    def test_parse_raises_on_an_unknown_correctable_label
        assert_raises(PrReport::Error) { PrReport::OffenseCounts.parse("3  A/B [Maybe Correctable]\n") }
    end

    def test_detailed_keeps_single_offense_cops_that_are_not_safe_correctable_in_order
        rows = [
            { count: 1, cop: "A/One", correctable: nil },
            { count: 1, cop: "B/Safe", correctable: :safe },
            { count: 1, cop: "C/Unsafe", correctable: :unsafe },
            { count: 2, cop: "D/Two", correctable: nil },
            { count: 11, cop: "E/Many", correctable: :unsafe }
        ]
        assert_equal ["A/One", "C/Unsafe"], PrReport::OffenseCounts.detailed(rows)
    end

    def test_detailed_is_empty_when_no_cop_qualifies
        assert_equal [], PrReport::OffenseCounts.detailed([{ count: 2, cop: "B/Two", correctable: nil }])
    end

    def test_safe_correctable_sums_only_safe_counts
        rows = [
            { count: 86, cop: "A/Safe", correctable: :safe },
            { count: 2, cop: "B/Unsafe", correctable: :unsafe },
            { count: 3, cop: "C/Safe", correctable: :safe },
            { count: 5, cop: "D/Plain", correctable: nil }
        ]
        assert_equal 89, PrReport::OffenseCounts.safe_correctable(rows)
    end

    def test_safe_correctable_is_zero_when_none_is_safe
        assert_equal 0, PrReport::OffenseCounts.safe_correctable([{ count: 2, cop: "B/Two", correctable: nil }])
    end

    def test_plain_drops_surrounding_blank_lines_and_labels_and_keeps_the_rest
        text = "\n\n86   Layout/SpaceAfterComma [Safe Correctable]\n" \
               "2    Lint/AmbiguousRange [Unsafe Correctable]\n" \
               "1    Layout/EndOfLine\n--\n89   Total in 1 files\n\n"

        expected = "86   Layout/SpaceAfterComma\n2    Lint/AmbiguousRange\n" \
                   "1    Layout/EndOfLine\n--\n89   Total in 1 files\n"
        assert_equal expected, PrReport::OffenseCounts.plain(text)
    end
end
