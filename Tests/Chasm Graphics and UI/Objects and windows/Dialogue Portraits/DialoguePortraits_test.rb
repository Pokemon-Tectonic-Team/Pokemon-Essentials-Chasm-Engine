require_relative "../../../support/test_helper"
require_relative "../../../support/graphics_folder"

class DialoguePortraitsTest < Minitest::Test
    SCREEN_WIDTH = 512
    PORTRAIT_WIDTH = 224
    PORTRAIT_HEIGHT = 288

    # Answers what PortraitAnchor.of reads from a message window.
    FakeWindow = Struct.new(:y, :height, :frameInsets)

    def anchorAt(y, height: 96, topInset: 0, bottomInset: 0)
        return PortraitAnchor.new(y, height, topInset, bottomInset)
    end

    def position(side, anchor)
        return portraitWindowPosition(side, PORTRAIT_WIDTH, PORTRAIT_HEIGHT, anchor, SCREEN_WIDTH)
    end

    def test_every_portrait_side_is_accepted
        [:left, :centre, :right].each { |side| assert_nil checkPortraitSide(side) }
    end

    def test_an_unknown_side_raises_naming_it
        error = assert_raises(ArgumentError) { checkPortraitSide(:center) }
        assert_includes error.message, ":center"
    end

    def test_a_message_code_is_not_a_side
        assert_raises(ArgumentError) { checkPortraitSide("ml") }
    end

    def test_nil_is_not_a_side
        assert_raises(ArgumentError) { checkPortraitSide(nil) }
    end

    def test_each_message_code_names_its_side
        assert_equal({ "ml" => :left, "mc" => :centre, "mr" => :right }, PORTRAIT_SIDES)
    end

    def test_an_anchor_reads_the_window_position_size_and_frame_insets
        anchor = PortraitAnchor.of(FakeWindow.new(288, 96, [4, 6]))
        assert_equal [288, 96, 4, 6], anchor.to_a
    end

    def test_a_left_portrait_sits_at_the_edge_margin
        x, = position(:left, anchorAt(288))
        assert_equal PORTRAIT_EDGE_MARGIN, x
    end

    def test_a_centre_portrait_is_centred_on_the_screen
        x, = position(:centre, anchorAt(288))
        assert_equal((SCREEN_WIDTH - PORTRAIT_WIDTH) / 2, x)
    end

    def test_a_right_portrait_sits_at_the_edge_margin_from_the_right
        x, = position(:right, anchorAt(288))
        assert_equal SCREEN_WIDTH - PORTRAIT_WIDTH - PORTRAIT_EDGE_MARGIN, x
    end

    def test_a_portrait_stands_with_its_image_on_the_window_top
        _, y = position(:left, anchorAt(288))
        assert_equal 288, y + PORTRAIT_HEIGHT - PORTRAIT_WINDOW_PADDING
    end

    def test_a_portrait_stands_on_the_visible_frame_below_a_transparent_top
        _, y = position(:left, anchorAt(288, topInset: 10))
        assert_equal 298, y + PORTRAIT_HEIGHT - PORTRAIT_WINDOW_PADDING
    end

    def test_a_portrait_hangs_from_the_bottom_of_a_window_at_the_screen_top
        _, y = position(:left, anchorAt(0, height: 96))
        assert_equal 96, y + PORTRAIT_WINDOW_PADDING
    end

    def test_a_hanging_portrait_hangs_from_the_visible_frame_above_a_transparent_bottom
        _, y = position(:left, anchorAt(0, height: 96, bottomInset: 6))
        assert_equal 90, y + PORTRAIT_WINDOW_PADDING
    end

    def test_a_window_above_the_screen_top_still_counts_as_at_the_top
        _, y = position(:left, anchorAt(-20, height: 96))
        assert_equal 76, y + PORTRAIT_WINDOW_PADDING
    end

    def test_a_window_one_pixel_below_the_screen_top_has_a_portrait_standing_on_it
        _, y = position(:left, anchorAt(1))
        assert_equal 1, y + PORTRAIT_HEIGHT - PORTRAIT_WINDOW_PADDING
    end

    def test_a_hanging_portrait_ignores_the_top_inset
        _, y = position(:left, anchorAt(0, height: 96, topInset: 10))
        assert_equal 96, y + PORTRAIT_WINDOW_PADDING
    end

    def test_a_standing_portrait_ignores_the_bottom_inset
        _, y = position(:left, anchorAt(288, bottomInset: 10))
        assert_equal 288, y + PORTRAIT_HEIGHT - PORTRAIT_WINDOW_PADDING
    end

    def test_a_side_portrait_fully_out_is_the_slide_distance_off_towards_its_edge
        assert_equal(-PORTRAIT_SLIDE_DISTANCE, portraitSlideOffset(:left, 0))
        assert_equal PORTRAIT_SLIDE_DISTANCE, portraitSlideOffset(:right, 0)
    end

    def test_a_portrait_fully_in_is_at_rest
        assert_equal 0, portraitSlideOffset(:left, 1)
        assert_equal 0, portraitSlideOffset(:right, 1)
    end

    def test_a_partway_slide_rounds_to_whole_pixels
        assert_equal(-90, portraitSlideOffset(:left, 0.3))
        assert_equal 90, portraitSlideOffset(:right, 0.3)
    end

    def test_the_centre_portrait_never_moves
        [0, 0.3, 1].each { |slide| assert_equal 0, portraitSlideOffset(:centre, slide) }
    end
end

class DefaultPortraitAnchorTest < Minitest::Test
    # Answers what pbRepositionMessageWindow reads from the game system.
    MessageSettings = Struct.new(:message_position, :message_frame)

    def run(...)
        GraphicsFolder.with { super }
    end

    def teardown
        $game_system = nil
    end

    # Runs the block with the screen height given, restoring the stub's after.
    def withScreenHeight(height)
        original = Graphics.method(:height)
        Graphics.define_singleton_method(:height) { height }
        yield
    ensure
        Graphics.define_singleton_method(:height, original)
    end

    # The message windows the block builds, each with the skins it was given.
    def messageWindowsBuilt
        built = []
        Window_AdvancedTextPokemon.define_singleton_method(:new) do |*args|
            super(*args).tap do |window|
                skins = []
                window.define_singleton_method(:setSkin) do |skin, *rest|
                    skins.push(skin)
                    super(skin, *rest)
                end
                built.push([window, skins])
            end
        end
        yield
        return built
    ensure
        Window_AdvancedTextPokemon.singleton_class.remove_method(:new)
    end

    def test_a_message_shows_two_lines_on_the_game_screen
        assert_equal 2, pbDefaultMessageLines
    end

    def test_a_message_shows_three_lines_on_a_screen_taller_than_400
        withScreenHeight(401) { assert_equal 3, pbDefaultMessageLines }
    end

    def test_portraits_stand_on_a_default_message_window_at_the_screen_bottom
        assert_equal [Graphics.height - 96, 96, 0, 0], defaultPortraitAnchor.to_a
    end

    def test_portraits_follow_the_message_position_option
        $game_system = MessageSettings.new(0, 0)
        assert_equal 0, defaultPortraitAnchor.y
    end

    def test_the_stand_in_message_window_is_a_hidden_speech_window_disposed_after
        built = messageWindowsBuilt { defaultPortraitAnchor }
        assert_equal 1, built.length
        window, skins = built.first
        assert_equal [MessageConfig.pbGetSpeechFrame], skins
        refute window.visible
        assert window.disposed?
    end
end
