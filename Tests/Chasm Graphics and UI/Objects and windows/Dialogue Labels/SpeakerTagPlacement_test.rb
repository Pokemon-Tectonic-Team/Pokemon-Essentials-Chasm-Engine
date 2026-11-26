require_relative "../../../support/test_helper"

class SpeakerTagPlacementTest < Minitest::Test
    SCREEN_WIDTH = 512
    TAG_WIDTH = 100

    def tagX(side, imageX)
        return speakerTagX(side, Rect.new(imageX, 40, 192, 256), TAG_WIDTH, SCREEN_WIDTH)
    end

    def test_a_left_portrait_has_its_tag_on_its_right
        assert_equal 24 + 192 + SPEAKER_TAG_GAP, tagX(:left, 24)
    end

    def test_a_right_portrait_has_its_tag_on_its_left
        assert_equal 296 - SPEAKER_TAG_GAP - TAG_WIDTH, tagX(:right, 296)
    end

    def test_a_centre_portrait_has_its_tag_on_its_left_when_it_fits
        assert_equal 160 - SPEAKER_TAG_GAP - TAG_WIDTH, tagX(:centre, 160)
    end

    def test_a_centre_tag_exactly_fitting_on_the_left_stays_there
        assert_equal 0, tagX(:centre, TAG_WIDTH + SPEAKER_TAG_GAP)
    end

    def test_a_centre_tag_that_does_not_fit_on_the_left_goes_right
        imageX = TAG_WIDTH + SPEAKER_TAG_GAP - 1
        assert_equal imageX + 192 + SPEAKER_TAG_GAP, tagX(:centre, imageX)
    end

    def test_a_tag_past_the_right_edge_is_kept_on_screen
        assert_equal SCREEN_WIDTH - TAG_WIDTH, tagX(:left, 300)
    end

    def test_a_tag_past_the_left_edge_is_kept_on_screen
        assert_equal 0, tagX(:right, 50)
    end

    def test_a_tag_as_wide_as_the_screen_fills_it
        imageRect = Rect.new(24, 40, 192, 256)
        assert_equal 0, speakerTagX(:left, imageRect, SCREEN_WIDTH, SCREEN_WIDTH)
    end

    def test_a_tag_wider_than_the_screen_raises
        imageRect = Rect.new(24, 40, 192, 256)
        error = assert_raises(ArgumentError) { speakerTagX(:left, imageRect, SCREEN_WIDTH + 1, SCREEN_WIDTH) }
        assert_includes error.message, (SCREEN_WIDTH + 1).to_s
    end
end
