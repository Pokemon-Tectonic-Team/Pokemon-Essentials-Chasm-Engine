require_relative "../../support/test_helper"
require_relative "../../../.github/scripts/pr_report/markdown"

class MarkdownTest < Minitest::Test
    M = PrReport::Markdown

    def test_code_block_removes_one_trailing_newline
        assert_equal "```text\na\nb\n```\n", M.code_block("a\nb\n")
        assert_equal "```text\na\n\n```\n", M.code_block("a\n\n")
        assert_equal "```text\na\n```\n", M.code_block("a")
    end

    def test_cut_lines_keeps_text_at_the_limit
        text = "x\n" * 200
        assert_equal text, M.cut_lines(text, limit: 200, note: "N")
    end

    def test_cut_lines_cuts_one_past_the_limit
        assert_equal "#{"x\n" * 200}\nN\n", M.cut_lines("x\n" * 201, limit: 200, note: "N")
    end

    def test_cut_lines_closes_an_open_fence
        assert_equal "```\na\nb\n```\n\nN\n", M.cut_lines("```\na\nb\nc\n", limit: 3, note: "N")
    end

    def test_cut_lines_closes_an_open_indented_fence
        assert_equal "  ```\na\n```\n\nN\n", M.cut_lines("  ```\na\nb\n", limit: 2, note: "N")
    end

    def test_cut_lines_leaves_a_closed_fence_alone
        assert_equal "```\na\n```\n\nN\n", M.cut_lines("```\na\n```\nb\n", limit: 3, note: "N")
    end

    def test_cut_chars_keeps_text_at_the_limit
        text = "aaaaaaaaa\n" * 3
        assert_equal 30, text.length
        assert_equal text, M.cut_chars(text, limit: 30, note: "NOTE!")
    end

    def test_cut_chars_cuts_one_over_at_a_line_end
        text = "#{"aaaaaaa\n" * 3}bbbbbbb"
        assert_equal 31, text.length

        result = M.cut_chars(text, limit: 30, note: "NOTE!")

        assert_equal "aaaaaaa\naaaaaaa\n\nNOTE!\n", result
        assert_operator result.length, :<=, 30
    end

    def test_cut_chars_closes_an_open_fence_within_the_limit
        text = "```\n#{"abcdefg\n" * 4}"
        assert_equal 36, text.length

        result = M.cut_chars(text, limit: 30, note: "NOTE!")

        assert_equal "```\nabcdefg\n```\n\nNOTE!\n", result
        assert_operator result.length, :<=, 30
    end

    def test_cut_chars_keeps_a_partial_line_when_there_is_no_newline
        result = M.cut_chars("x" * 40, limit: 30, note: "NOTE!")

        assert_match(/\Ax+\n\nNOTE!\n\z/, result)
        assert_operator result.length, :<=, 30
    end
end
