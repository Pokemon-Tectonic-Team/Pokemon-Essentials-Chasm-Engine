require_relative "../../../support/test_helper"

class WindowskinInsetsTest < Minitest::Test
    Area = Struct.new(:x, :y, :width, :height)

    # A bitmap whose pixels are opaque only in the given rows, recording each
    # pixel read.
    class RowsBitmap
        attr_reader :reads

        def initialize(opaqueRows)
            @opaqueRows = opaqueRows
            @reads = []
        end

        def get_pixel(x, y)
            @reads.push([x, y])
            return Color.new(0, 0, 0, @opaqueRows.include?(y) ? 255 : 0)
        end
    end

    def test_counts_transparent_rows_from_the_top
        bitmap = RowsBitmap.new(3..9)
        assert_equal 3, transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), false)
    end

    def test_counts_transparent_rows_from_the_bottom
        bitmap = RowsBitmap.new(0..6)
        assert_equal 3, transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), true)
    end

    def test_an_opaque_first_row_counts_none
        bitmap = RowsBitmap.new(0..9)
        assert_equal 0, transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), false)
    end

    def test_a_fully_transparent_rect_counts_every_row_reading_each_once
        bitmap = RowsBitmap.new([])
        assert_equal 10, transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), false)
        assert_equal((0...10).to_a, bitmap.reads.map(&:last))
    end

    def test_counting_stops_at_the_first_opaque_row
        bitmap = RowsBitmap.new(3..9)
        transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), false)
        assert_equal [0, 1, 2, 3], bitmap.reads.map(&:last)
    end

    def test_rows_are_counted_within_the_rect_not_the_whole_bitmap
        bitmap = RowsBitmap.new(24..39)
        assert_equal 4, transparentRowsAt(bitmap, Area.new(32, 20, 16, 20), false)
        assert_equal 2, transparentRowsAt(RowsBitmap.new(20..37), Area.new(32, 20, 16, 20), true)
    end

    def test_each_row_is_judged_by_its_pixel_at_the_rect_middle
        bitmap = RowsBitmap.new(2..9)
        transparentRowsAt(bitmap, Area.new(32, 0, 16, 10), false)
        assert_equal [40], bitmap.reads.map(&:first).uniq
    end

    def test_a_partly_transparent_pixel_is_opaque
        bitmap = Object.new
        def bitmap.get_pixel(_x, y)
            return Color.new(0, 0, 0, y == 0 ? 0 : 1)
        end
        assert_equal 1, transparentRowsAt(bitmap, Area.new(0, 0, 16, 10), false)
    end
end
