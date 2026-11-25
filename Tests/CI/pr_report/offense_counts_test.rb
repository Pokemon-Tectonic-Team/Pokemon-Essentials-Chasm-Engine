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

    def test_once_returns_cops_with_exactly_one_offense_in_order
        rows = [
            { count: 1, cop: "A/One", correctable: nil },
            { count: 2, cop: "B/Two", correctable: nil },
            { count: 1, cop: "C/One", correctable: :safe },
            { count: 11, cop: "D/Many", correctable: nil }
        ]
        assert_equal ["A/One", "C/One"], PrReport::OffenseCounts.once(rows)
    end

    def test_once_is_empty_when_no_cop_has_one
        assert_equal [], PrReport::OffenseCounts.once([{ count: 2, cop: "B/Two", correctable: nil }])
    end
end
