require_relative "../../support/test_helper"
require_relative "../../support/graphics_folder"

# PngAnimatedBitmap: a sheet whose name starts with [frames] or [frames,delay] is that many
# animation frames side by side, each shown for delay game frames.
class AnimatedBitmapTest < Minitest::Test
    IMAGES = {
        "Graphics/Pictures/[2]Blink" => [200, 50],
        "Graphics/Pictures/[2,4]Blink" => [200, 50],
        "Graphics/Pictures/[2,0]Blink" => [200, 50],
        "Graphics/Pictures/[3]Blink" => [200, 50],
    }.freeze

    def run(...)
        GraphicsFolder.with(IMAGES) { super }
    end

    def animated(name)
        return AnimatedBitmap.new("Graphics/Pictures/#{name}.png")
    end

    def test_a_sheet_splits_into_its_frames
        bitmap = animated("[2,4]Blink")
        assert_equal 2, bitmap.length
        assert_equal [100, 50], [bitmap.width, bitmap.height]
    end

    def test_each_frame_shows_for_the_delay
        bitmap = animated("[2,4]Blink")
        3.times { bitmap.update }
        assert_equal 0, bitmap.currentIndex
        bitmap.update
        assert_equal 1, bitmap.currentIndex
    end

    def test_a_sheet_with_no_delay_shows_each_frame_for_ten
        bitmap = animated("[2]Blink")
        assert_equal 2 * 10, bitmap.totalFrames
    end

    def test_a_zero_delay_raises
        error = assert_raises(RuntimeError) { animated("[2,0]Blink") }
        assert_equal "Invalid frame delay in [2,0]Blink.png", error.message
    end

    def test_a_sheet_that_does_not_split_evenly_raises
        assert_raises(RuntimeError) { animated("[3]Blink") }
    end
end
