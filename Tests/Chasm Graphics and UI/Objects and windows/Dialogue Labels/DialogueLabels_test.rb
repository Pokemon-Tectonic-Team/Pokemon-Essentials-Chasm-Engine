require_relative "../../../support/test_helper"
require_relative "../../../support/graphics_folder"

class DialogueLabelsTest < Minitest::Test
    # Stands in for a trainer record: to_trainer builds a whole NPCTrainer from the game's data.
    FakeTrainerRecord = Struct.new(:full_name) do
        def to_trainer
            return self
        end
    end

    # A trainer record whose to_trainer fails.
    class BrokenTrainerRecord
        def to_trainer
            raise ArgumentError, "broken party"
        end
    end

    # Answers what positionSpeakerWindow reads from a message window.
    MessageWindow = Struct.new(:x, :y, :width, :height, :z)
    MESSAGE = MessageWindow.new(16, 288, 480, 96, 200)
    LEFT_IMAGE = Rect.new(24, 32, PORTRAIT_FRAME_WIDTH, PORTRAIT_FRAME_HEIGHT)

    def run(...)
        GraphicsFolder.with { super }
    end

    def teardown
        removeSpeaker
    end

    def tag
        return $SpeakerNameWindow
    end

    # Counts the tag's width writes, each of which redraws its text.
    def countWidthWrites
        writes = []
        tag.define_singleton_method(:width=) do |value|
            writes.push(value)
            super(value)
        end
        return writes
    end

    def test_setting_a_speaker_builds_a_hidden_tag_in_the_speech_skin
        setSpeaker("Val", :viewport)
        assert_instance_of SpeakerNameWindow, tag
        assert_equal "#{MessageConfig.speechFrameName}.png", tag.windowskin.path
        assert_equal ["Val", :viewport, false], [tag.text, tag.viewport, tag.visible]
    end

    def test_a_new_tag_stands_at_the_screen_bottom_above_message_windows
        setSpeaker("Val")
        assert_equal [Graphics.height - tag.height, 99_999], [tag.y, tag.z]
    end

    def test_setting_another_speaker_reuses_the_tag
        setSpeaker("Val")
        first = tag
        setSpeaker("Professor Oakwood")
        assert_same first, tag
        assert_equal "Professor Oakwood", tag.text
    end

    def test_a_short_name_gets_the_minimum_width_but_remembers_its_fit
        setSpeaker("Al")
        assert_equal SPEAKER_TAG_MIN_WIDTH, tag.width
        assert_operator tag.fitWidth, :<, SPEAKER_TAG_MIN_WIDTH
    end

    def test_a_long_name_is_as_wide_as_its_text
        setSpeaker("Professor Oakwood of the Western Reaches")
        assert_operator tag.fitWidth, :>, SPEAKER_TAG_MIN_WIDTH
        assert_equal tag.fitWidth, tag.width
    end

    def test_refreshing_with_no_tag_does_nothing
        refreshSpeakerWindow
        assert_nil tag
    end

    def test_showing_and_hiding_the_tag
        setSpeaker("Val")
        showSpeaker
        assert speakerNameWindowVisible?
        hideSpeaker
        refute speakerNameWindowVisible?
    end

    def test_showing_hiding_and_removing_with_no_tag_do_nothing
        showSpeaker
        hideSpeaker
        removeSpeaker
        assert_nil speakerNameWindowVisible?
    end

    def test_removing_disposes_the_tag
        setSpeaker("Val")
        window = tag
        removeSpeaker
        assert window.disposed?
        assert_nil tag
    end

    def test_a_trainer_speaker_is_named_in_full
        GameData::Trainer::DATA[[:LEADER, "Val", 0]] = FakeTrainerRecord.new("Leader Val")
        setSpeakerTrainer(:LEADER, "Val")
        assert_equal "Leader Val", tag.text
    end

    def test_an_unknown_trainer_is_logged_not_shown
        setSpeakerTrainer(:LEADER, "Nobody")
        assert_nil tag
    end

    def test_a_trainer_named_by_something_other_than_a_string_is_logged_not_shown
        setSpeakerTrainer(:LEADER, nil)
        assert_nil tag
    end

    def test_an_error_building_a_known_trainer_is_not_hidden
        GameData::Trainer::DATA[[:LEADER, "Val", 0]] = BrokenTrainerRecord.new
        assert_raises(ArgumentError) { setSpeakerTrainer(:LEADER, "Val") }
    end

    def test_positioning_with_no_tag_does_nothing
        assert_nil positionSpeakerWindow(MESSAGE, nil)
    end

    def test_with_no_speaker_the_tag_sits_on_the_message_window_left
        setSpeaker("Al")
        positionSpeakerWindow(MESSAGE, nil)
        assert_equal SPEAKER_TAG_MIN_WIDTH, tag.width
        assert_equal [MESSAGE.x + 12, MESSAGE.y - tag.height + 12, MESSAGE.z + 1], [tag.x, tag.y, tag.z]
    end

    def test_beside_a_speaking_portrait_the_tag_shrinks_to_its_text
        setSpeaker("Al")
        positionSpeakerWindow(MESSAGE, [:left, LEFT_IMAGE])
        assert_equal tag.fitWidth, tag.width
        assert_equal speakerTagX(:left, LEFT_IMAGE, tag.fitWidth, Graphics.width), tag.x
        assert_equal [MESSAGE.y - tag.height + 12, MESSAGE.z + 1], [tag.y, tag.z]
    end

    def test_the_width_is_only_written_when_it_changes
        setSpeaker("Al")
        writes = countWidthWrites
        3.times { positionSpeakerWindow(MESSAGE, nil) }
        assert_empty writes
        3.times { positionSpeakerWindow(MESSAGE, [:left, LEFT_IMAGE]) }
        assert_equal [tag.fitWidth], writes
    end
end
