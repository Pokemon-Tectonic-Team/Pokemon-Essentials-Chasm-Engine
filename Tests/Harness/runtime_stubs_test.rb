require_relative "../support/test_helper"

class RuntimeStubsTest < Minitest::Test
    def test_color_defaults_to_opaque
        color = Color.new(1, 2, 3)
        assert_equal [1, 2, 3, 255], [color.red, color.green, color.blue, color.alpha]
    end

    def test_color_keeps_a_given_alpha
        assert_equal 40, Color.new(1, 2, 3, 40).alpha
    end

    def test_rect_keeps_its_position_and_size
        rect = Rect.new(1, 2, 3, 4)
        assert_equal [1, 2, 3, 4], [rect.x, rect.y, rect.width, rect.height]
    end

    def test_graphics_has_the_game_screen_size
        assert_equal [Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT], [Graphics.width, Graphics.height]
    end

    def test_graphics_runs_at_sixty_frames_a_second
        assert_equal 60, Graphics.frame_rate
    end

    def test_the_data_directory_exists
        assert File.directory?(System.data_directory)
    end

    def test_echoln_prints_nothing
        out, err = capture_io { echoln("a", "b") }

        assert_empty out
        assert_empty err
    end
end
