require_relative "../../support/test_helper"

class FaceSpecsTest < Minitest::Test
    def test_a_bare_name_is_frame_zero
        assert_equal ["Val", 0], parseFaceSpec("Val")
    end

    def test_a_name_and_index_split_at_the_comma
        assert_equal ["Val", 2], parseFaceSpec("Val,2")
    end

    def test_only_the_first_comma_splits
        assert_equal ["Val", 3], parseFaceSpec("Val,3,1")
    end

    def test_an_empty_spec_has_no_name
        assert_equal [nil, 0], parseFaceSpec("")
    end

    def test_an_index_that_is_not_a_number_is_frame_zero
        assert_equal ["Val", 0], parseFaceSpec("Val,happy")
    end

    def test_an_explicit_zero_index_is_frame_zero
        assert_equal ["Val", 0], parseFaceSpec("Val,0")
    end

    def test_an_animated_sheet_name_keeps_the_comma_in_its_brackets
        assert_equal ["[2,10]Val", 0], parseFaceSpec("[2,10]Val")
    end

    def test_an_animated_sheet_name_takes_an_index_after_it
        assert_equal ["[2,10]Val", 1], parseFaceSpec("[2,10]Val,1")
    end

    def test_an_animated_sheet_name_with_a_frame_count_alone_takes_an_index
        assert_equal ["[2]Val", 3], parseFaceSpec("[2]Val,3")
    end

    def test_brackets_holding_anything_but_numbers_split_as_usual
        assert_equal ["[a", 0], parseFaceSpec("[a,b]Val")
    end

    def test_brackets_later_in_a_name_split_as_usual
        assert_equal ["Val[2", 10], parseFaceSpec("Val[2,10]")
    end

    def test_a_negative_index_raises_naming_the_face
        error = assert_raises(ArgumentError) { parseFaceSpec("Val,-1") }
        assert_includes error.message, '"Val,-1"'
    end

    def rectFields(rect)
        return [rect.x, rect.y, rect.width, rect.height]
    end

    def test_frame_zero_is_the_top_left
        assert_equal [0, 0, 192, 256], rectFields(faceFrameRect(0, 192, 256))
    end

    def test_frames_run_along_a_row_of_four
        assert_equal [576, 0, 192, 256], rectFields(faceFrameRect(3, 192, 256))
    end

    def test_the_fifth_frame_starts_the_next_row
        assert_equal [0, 256, 192, 256], rectFields(faceFrameRect(4, 192, 256))
    end

    def test_frames_use_the_given_frame_size
        assert_equal [192, 96, 96, 96], rectFields(faceFrameRect(6, 96, 96))
    end
end
