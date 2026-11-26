require_relative "../../../support/test_helper"

# Untested here: showPortrait with a valid side, which builds a message window
# for its anchor, and waitForPortraits while portraits are moving, which runs
# the game's frame loop. Both are on the in-game checklist.
class PortraitCommandsTest < Minitest::Test
    # Stands in for DialoguePortraitSet; records what the commands ask of it.
    class FakePortraitSet
        attr_reader :calls
        attr_writer :animating

        def initialize
            @calls = []
            @animating = false
        end

        def hide(side)
            @calls.push([:hide, side])
        end

        def hideAll
            @calls.push([:hideAll])
        end

        def speaker=(side)
            @calls.push([:speaker, side])
        end

        def animating?
            return @animating
        end
    end

    # Answers what pbDialoguePortraits reads from the map scene.
    FakeSpritesetGlobal = Struct.new(:portraits)

    def setup
        @portraits = FakePortraitSet.new
        putOnMap(FakeSpritesetGlobal.new(@portraits))
    end

    def teardown
        $scene = nil
    end

    def putOnMap(spritesetGlobal)
        $scene = Scene_Map.new
        $scene.instance_variable_set(:@spritesetGlobal, spritesetGlobal)
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
        putOnMap(nil)
        assert_nil pbDialoguePortraits
    end

    def test_hiding_a_portrait_sends_its_side_out
        hidePortrait(:right)
        assert_equal [[:hide, :right]], @portraits.calls
    end

    def test_hiding_an_unknown_side_raises_and_hides_nothing
        assert_raises(ArgumentError) { hidePortrait(:center) }
        assert_empty @portraits.calls
    end

    def test_showing_an_unknown_side_raises
        assert_raises(ArgumentError) { showPortrait(:center, "Val") }
    end

    def test_hiding_every_portrait
        hidePortraits
        assert_equal [[:hideAll]], @portraits.calls
    end

    def test_setting_the_speaker
        setPortraitSpeaker(:right)
        assert_equal [[:speaker, :right]], @portraits.calls
    end

    def test_setting_nobody_as_speaker
        setPortraitSpeaker(nil)
        assert_equal [[:speaker, nil]], @portraits.calls
    end

    def test_waiting_returns_at_once_when_nothing_moves
        assert_nil waitForPortraits
    end

    def test_every_command_raises_off_the_map
        $scene = Object.new
        commands = [-> { showPortrait(:left, "Val") }, -> { hidePortrait(:left) }, -> { hidePortraits },
                    -> { setPortraitSpeaker(:left) }, -> { waitForPortraits }]
        commands.each do |command|
            error = assert_raises(RuntimeError) { command.call }
            assert_equal "dialogue portraits only show on the map", error.message
        end
    end
end
