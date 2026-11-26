require_relative "../support/test_helper"
require_relative "../support/graphics_folder"

class RuntimeStubsTest < Minitest::Test
    def colorOf(color)
        return [color.red, color.green, color.blue, color.alpha]
    end

    def rectOf(rect)
        return [rect.x, rect.y, rect.width, rect.height]
    end

    def test_color_defaults_to_opaque
        assert_equal [1, 2, 3, 255], colorOf(Color.new(1, 2, 3))
    end

    def test_color_keeps_a_given_alpha
        assert_equal 40, Color.new(1, 2, 3, 40).alpha
    end

    def test_color_with_no_arguments_is_opaque_black
        assert_equal [0, 0, 0, 255], colorOf(Color.new)
    end

    def test_color_set_replaces_every_field
        assert_equal [4, 5, 6, 7], colorOf(Color.new(1, 2, 3).set(4, 5, 6, 7))
    end

    def test_tone_defaults_to_no_change
        tone = Tone.new
        assert_equal [0, 0, 0, 0], [tone.red, tone.green, tone.blue, tone.gray]
    end

    def test_tone_set_replaces_every_field
        tone = Tone.new.set(1, 2, 3, 4)
        assert_equal [1, 2, 3, 4], [tone.red, tone.green, tone.blue, tone.gray]
    end

    def test_rect_keeps_its_position_and_size
        assert_equal [1, 2, 3, 4], rectOf(Rect.new(1, 2, 3, 4))
    end

    def test_rect_with_no_arguments_is_empty
        assert_equal [0, 0, 0, 0], rectOf(Rect.new)
    end

    def test_rect_set_and_empty
        rect = Rect.new(1, 2, 3, 4)
        assert_equal [5, 6, 7, 8], rectOf(rect.set(5, 6, 7, 8))
        rect.empty
        assert_equal [0, 0, 0, 0], rectOf(rect)
    end

    def test_a_font_takes_the_default_name_and_size
        name = Font.default_name
        size = Font.default_size
        Font.default_name = "Test Font"
        Font.default_size = 18
        assert_equal ["Test Font", 18], [Font.new.name, Font.new.size]
    ensure
        Font.default_name = name
        Font.default_size = size
    end

    def test_a_font_with_no_default_size_is_24
        size = Font.default_size
        Font.default_size = nil
        assert_equal 24, Font.new.size
    ensure
        Font.default_size = size
    end

    def test_a_blank_bitmap_has_its_size
        bitmap = Bitmap.new(30, 20)
        assert_equal [30, 20], [bitmap.width, bitmap.height]
        assert_equal [0, 0, 30, 20], rectOf(bitmap.rect)
        assert_nil bitmap.path
    end

    def test_a_bitmap_from_a_file_has_the_png_size
        GraphicsFolder.with("Graphics/Pictures/Sign" => [40, 50]) do
            bitmap = Bitmap.new("Graphics/Pictures/Sign.png")
            assert_equal ["Graphics/Pictures/Sign.png", 40, 50], [bitmap.path, bitmap.width, bitmap.height]
        end
    end

    def test_a_bitmap_from_a_missing_file_raises
        Dir.mktmpdir do |dir|
            assert_raises(Errno::ENOENT) { Bitmap.new(File.join(dir, "none.png")) }
        end
    end

    def test_a_bitmap_from_a_file_that_is_not_a_png_raises
        Dir.mktmpdir do |dir|
            path = File.join(dir, "text.png")
            File.write(path, "not an image")
            assert_raises(Errno::ENOENT) { Bitmap.new(path) }
        end
    end

    def test_a_bitmap_records_each_blt_with_its_source
        target = Bitmap.new(10, 10)
        source = Bitmap.new(20, 20)
        rect = Rect.new(1, 2, 3, 4)
        target.blt(5, 6, source, rect)
        target.stretch_blt(Rect.new(7, 8, 9, 9), source, rect)
        assert_equal [[5, 6, source, rect], [7, 8, source, rect]], target.blts
    end

    def test_a_bitmap_records_the_text_drawn
        bitmap = Bitmap.new(100, 100)
        bitmap.draw_text(0, 0, 50, 20, "left")
        bitmap.draw_text(Rect.new(0, 0, 50, 20), "aligned", 1)
        bitmap.draw_text(0, 0, 50, 20, 42)
        bitmap.draw_text(Rect.new(0, 0, 50, 20), 7)
        assert_equal %w[left aligned 42 7], bitmap.texts
    end

    def test_a_bitmap_counts_its_clears
        bitmap = Bitmap.new(10, 10)
        2.times { bitmap.clear }
        assert_equal 2, bitmap.clears
    end

    def test_text_is_measured_at_a_fixed_width_a_character
        assert_equal Bitmap::TEXT_CHAR_WIDTH * 3, Bitmap.new(10, 10).text_size("abc").width
    end

    def test_every_pixel_is_opaque
        assert_equal 255, Bitmap.new(10, 10).get_pixel(3, 4).alpha
    end

    def test_a_bitmap_is_still_unless_given_frames
        bitmap = Bitmap.new(10, 10)
        refute bitmap.animated?
        bitmap.frame_count = 3
        assert bitmap.animated?
    end

    def test_disposing_a_bitmap
        bitmap = Bitmap.new(10, 10)
        bitmap.dispose
        assert bitmap.disposed?
    end

    def test_a_sprite_shows_its_whole_bitmap
        sprite = Sprite.new(:viewport)
        sprite.bitmap = Bitmap.new(30, 20)
        assert_equal [0, 0, 30, 20], rectOf(sprite.src_rect)
        assert_equal [30, 20, :viewport], [sprite.width, sprite.height, sprite.viewport]
    end

    def test_a_viewport_takes_a_rect_or_its_fields
        assert_equal [1, 2, 3, 4], rectOf(Viewport.new(1, 2, 3, 4).rect)
        assert_equal [5, 6, 7, 8], rectOf(Viewport.new(Rect.new(5, 6, 7, 8)).rect)
    end

    def test_disposing_a_sprite_or_viewport
        [Sprite.new, Viewport.new(0, 0, 1, 1)].each do |drawable|
            drawable.dispose
            assert drawable.disposed?
        end
    end

    def test_graphics_has_the_game_screen_size
        assert_equal [Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT], [Graphics.width, Graphics.height]
    end

    def test_graphics_runs_at_sixty_frames_a_second
        assert_equal 60, Graphics.frame_rate
    end

    def test_each_graphics_update_is_a_frame
        start = Graphics.frame_count
        2.times { Graphics.update }
        assert_equal start + 2, Graphics.frame_count
    end

    def test_the_image_cache_starts_as_a_hash
        assert_kind_of Hash, RPG::Cache.instance_variable_get(:@cache)
    end

    def test_the_data_directory_is_a_folder_of_the_run_own
        assert File.directory?(System.data_directory)
        refute_equal File.expand_path(Dir.tmpdir), File.expand_path(System.data_directory)
    end

    def test_the_platform_is_not_android
        refute_match(/android/i, System.platform)
    end

    def test_input_update_does_nothing
        assert_nil Input.update
    end

    def test_save_data_marshals_the_object_into_the_file
        Dir.mktmpdir do |dir|
            path = File.join(dir, "data.dat")
            save_data({ a: [1, "b"] }, path)

            assert_equal({ a: [1, "b"] }, Marshal.load(File.binread(path))) # rubocop:disable Security/MarshalLoad -- the file the test just wrote
        end
    end

    def test_echoln_prints_nothing
        out, err = capture_io { echoln("a", "b") }

        assert_empty out
        assert_empty err
    end
end
