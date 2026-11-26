require_relative "../../support/test_helper"

class BitmapHueShiftsTest < Minitest::Test
    # Stands in for an AnimatedBitmap: copy returns its frames, each recording the hue changes
    class FakeAnimatedBitmap
        attr_reader :frames

        def initialize(frames) = @frames = frames
        def copy = @frames
        def dispose; end
    end

    class FakeFrame
        attr_reader :hue_changes

        def initialize = @hue_changes = []
        def hue_change(shift) = @hue_changes.push(shift)
    end

    # Stands in for a bitmap's pixels, by [x, y]
    class FakePixels
        attr_reader :pixels

        def initialize(width, height, color)
            @pixels = {}
            (0...width).each { |x| (0...height).each { |y| @pixels[[x, y]] = color.clone } }
        end

        def width = @pixels.keys.map(&:first).max + 1
        def height = @pixels.keys.map(&:last).max + 1
        def get_pixel(x, y) = @pixels[[x, y]].clone
        def set_pixel(x, y, color) = @pixels[[x, y]] = color
    end

    def test_shift_species_bitmap_hue_shifts_by_the_line_start_id_number
        create_species(id: :BASE, id_number: 7, evolutions: [[:MID, :Level, 10, false]])
        create_species(id: :MID, id_number: 8, evolutions: [[:BASE, :Level, 10, true], [:TOP, :Level, 20, false]])
        create_species(id: :TOP, id_number: 9, evolutions: [[:MID, :Level, 20, true]])
        frames = [FakeFrame.new, FakeFrame.new]

        shiftSpeciesBitmapHue(FakeAnimatedBitmap.new(frames), :TOP)

        assert_equal [[hue_shift_from_id(7)]] * 2, frames.map(&:hue_changes)
    end

    def test_hue_shift_from_id_stays_within_60_degrees_of_red
        shifts = (0...200).map { |id| hue_shift_from_id(id) }

        assert(shifts.each_slice(2).all? { |even, odd| (30...90).cover?(even) && (271..330).cover?(odd) })
    end

    def test_shade_change_clamps_each_channel
        bitmap = FakePixels.new(1, 1, Color.new(250, 64, 5))

        shade_change(bitmap, 255) # Doubles each channel, then stretches it away from 128

        color = bitmap.pixels[[0, 0]]
        assert_equal [255, 128, 0], [color.red, color.green, color.blue]
    end

    def test_shade_change_skips_transparent_pixels
        bitmap = FakePixels.new(1, 1, Color.new(250, 128, 5, 0))

        shade_change(bitmap, 255)

        color = bitmap.pixels[[0, 0]]
        assert_equal [250, 128, 5], [color.red, color.green, color.blue]
    end
end
