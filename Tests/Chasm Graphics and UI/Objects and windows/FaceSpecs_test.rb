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
