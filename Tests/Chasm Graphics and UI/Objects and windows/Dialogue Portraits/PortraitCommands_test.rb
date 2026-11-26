require_relative "../../../support/test_helper"
require_relative "../../../support/graphics_folder"

class PortraitCommandsTest < Minitest::Test
    # The map, as far as portraits see it: pbWait's frame updates the map, whose global spriteset
    # updates its portraits as in a conversation. The real miniupdate runs the whole map.
    class PortraitMapScene < Scene_Map
        def initialize(portraits)
            super()
            @spritesetGlobal = Struct.new(:portraits).new(portraits)
        end

        def miniupdate
            @spritesetGlobal.portraits.update(true)
        end
    end

    IMAGES = { "Graphics/Faces/Val" => [768, 512], "Graphics/Faces/Ana" => [768, 512] }.freeze

    def run(...)
        GraphicsFolder.with(IMAGES) { super }
    end

    def setup
        @portraits = DialoguePortraitSet.new
        $scene = PortraitMapScene.new(@portraits)
    end

    def teardown
        @portraits.dispose
        $scene = nil
    end

    def shown(side)
        return @portraits.instance_variable_get(:@shown)[side]
    end

    def windowOf(portrait)
        return portrait.instance_variable_get(:@window)
    end

    def test_the_map_has_its_spriteset_portraits
        assert_same @portraits, pbDialoguePortraits
    end

    def test_there_are_no_portraits_off_the_map
        $scene = Object.new
        assert_nil pbDialoguePortraits
    end

    def test_there_are_no_portraits_with_no_scene
        $scene = nil
        assert_nil pbDialoguePortraits
    end

    def test_there_are_no_portraits_before_the_map_has_a_spriteset
        $scene = Scene_Map.new
        assert_nil pbDialoguePortraits
    end

    def test_showing_stands_where_the_next_message_will_and_speaks
        showPortrait(:left, "Val")
        anchor = PortraitAnchor.new(Graphics.height - 96, 96, 0, 0)
        expected = portraitWindowPosition(:left, PORTRAIT_FRAME_WIDTH + 32, PORTRAIT_FRAME_HEIGHT + 32,
            anchor, Graphics.width)[1]
        assert_equal expected, windowOf(shown(:left)).y
        assert_equal :left, @portraits.speaker
    end

    def test_showing_no_face_sends_the_side_out
        showPortrait(:left, "Val")
        portrait = shown(:left)
        showPortrait(:left, "")
        assert_nil @portraits.speaker
        waitForPortraits
        assert windowOf(portrait).disposed?
    end

    def test_hiding_one_side_leaves_the_other
        showPortrait(:left, "Val")
        showPortrait(:right, "Ana")
        left = shown(:left)
        hidePortrait(:left)
        waitForPortraits
        assert windowOf(left).disposed?
        refute windowOf(shown(:right)).disposed?
    end

    def test_hiding_every_side
        showPortrait(:left, "Val")
        showPortrait(:right, "Ana")
        portraits = [shown(:left), shown(:right)]
        hidePortraits
        waitForPortraits
        assert(portraits.all? { |portrait| windowOf(portrait).disposed? })
    end

    def test_setting_the_speaker_and_nobody
        showPortrait(:left, "Val")
        setPortraitSpeaker(:centre)
        assert_equal :centre, @portraits.speaker
        setPortraitSpeaker(nil)
        assert_nil @portraits.speaker
    end

    def test_waiting_lasts_until_the_portraits_settle
        showPortrait(:left, "Val")
        start = Graphics.frame_count
        waitForPortraits
        refute @portraits.animating?
        assert_in_delta PORTRAIT_SLIDE_SECONDS * Graphics.frame_rate, Graphics.frame_count - start, 1
    end

    def test_waiting_with_nothing_moving_returns_at_once
        start = Graphics.frame_count
        waitForPortraits
        assert_equal start, Graphics.frame_count
    end

    def test_an_unknown_side_is_refused_naming_it
        [-> { showPortrait(:top, "Val") }, -> { hidePortrait(:top) }, -> { setPortraitSpeaker(:top) }].each do |command|
            error = assert_raises(ArgumentError, &command)
            assert_includes error.message, ":top"
        end
        refute @portraits.animating?
    end

    def test_every_command_raises_off_the_map
        $scene = Object.new
        commands = [-> { showPortrait(:left, "Val") }, -> { hidePortrait(:left) }, -> { hidePortraits },
                    -> { setPortraitSpeaker(:left) }, -> { waitForPortraits }]
        commands.each do |command|
            error = assert_raises(RuntimeError, &command)
            assert_equal "dialogue portraits only show on the map", error.message
        end
    end
end
